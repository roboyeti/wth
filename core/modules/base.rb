# Author: BeRogue01
# License: See LICENSE file
# Date: 10/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
require 'json'
require 'pastel'
require 'terminal-table'

using DynamicHash

class Base
  attr_accessor :title
  attr_reader :config, :last_check, :frequency, :data, :port, :events, :page, :responses
 
  def initialize(p={})
    @config = p[:config]
    @frequency = @config["every"] || 12
    @port = @config["port"] || 0
    @page = @config["page"] || 1
    @last_check = Time.now - (@frequency*2)
    @title = @config[:title] || 'Undefined???'
    @down = {}
    @data = {}
    @events = []
    @responses = {}
  end

  [:check, :console_out, :format].each {|m|
    # TODO - add error output for no default available...    
  } 

  # Caller should collect and clear per iteration
  def clear_events
    @events = []    
  end

  def nice_title
    if config['extra']
      "#{title} #{config['extra']}"
    elsif config['coin']
      "#{title} - #{config['coin']}"
    else
      title
    end
  end

  def standalone?
    @standalone == 1 || @standalone == true || @standalone == 'true'
  end
  
  # Check all nodes provided in a module config.
  #
  def check_all
    @events = []
    tchk = (Time.now - @last_check)

    if @data.empty? || tchk > @frequency
      out = []
      @data = { addresses: {} }    
      addresses = @config['nodes'].keys.sort
      
      addresses.each {|k|
        v = @config['nodes'][k]
        @data['addresses'][k] = {}
        begin
          if @down[k]
            if (Time.now - @down[k]) < 180
                  @data['addresses'][k] = {
                    "down" => true,
                    "message" => "Service down!  Checked @ #{@down[k]} #{(Time.now - @down[k]).round(2)} seconds ago",
                    "time"  => Time.now,
                  }
            else
              @down.delete(k)
              h = self.check(v,k)
              @data['addresses'][k] = h
            end
          else
            h = self.check(v,k)
            @data['addresses'][k] = h
          end
        rescue => e
          @down[k] = Time.now
          @events << "#{Time.now} : #{k} : #{e}"
          @data['addresses'][k] = {
            'down' => true,
            'error' => e,
            'backtrace' => e.backtrace[0..4],
            'time'  => Time.now,
            'message' => "Service down!  Checked @ #{@down[k]} #{(Time.now - @down[k]).round(2)} seconds ago",
          }
        end
      }
      @last_check = Time.now
    end

    @data[:last_check_ago] = (Time.now - @last_check).to_i
    @data
  end

  # Quick and simple rest call with URL.
  # TODO: Get timeout working. Execute needs trouble shooting or gem replaced...
  def simple_rest(url,timeout=120)
#    s = if proxy
#          RestClient::Request.execute(:method => :get, :url => url, :proxy => proxy, :headers => {}, :timeout => timeout)
#        else
#          RestClient::Request.execute(:method => :get, :url => url, :headers => {}, :timeout => timeout)          
#        end
    s = RestClient.get url
    res = s && s.body ? JSON.parse(s.body) : {}
    begin
      s.closed
    rescue
    end
    res
  end

  # Structure of GPU workers
  def worker_structure
    OpenStruct.new({
      :name     =>"",
      :address  =>"",
      :miner    =>"",
      :uptime   =>0,
      :algo     => "",
      :coin     => "",
      :pool     => "",
      :combined_speed =>0,
      :total_shares   =>0,
      :rejected_shares=>0,
      :invalid_shares  =>0,
      :power_total    =>0,
      :gpu            =>{},
      :cpu            =>'',
      :system         =>{},
    })
  end

  # Structure of GPU data
  # * GPU power may not be available
  # * id may not match "system" id.  PCI bus id is more reliable.
  def gpu_structure
    OpenStruct.new({
      :pci        =>"0",
      :id         =>0,
      :gpu_speed  =>0.0,
      :gpu_temp   =>0,
      :gpu_fan    =>0,
      :gpu_power  =>0,
      :speed_unit =>""
    })
  end

  # Structure of GPU device data
  # * GPU power may not be available
  # * id may not match "system" id.  PCI bus id is more reliable.
  def gpu_device_structure
    OpenStruct.new({
      :pci        =>"0",
      :id         =>0,
      :gpu_temp   =>0,
      :gpu_fan    =>0,
      :gpu_power  =>0,
    })
  end

  def cpu_structure
    OpenStruct.new({
      :name       =>"",
      :id         =>0,
      :cpu_temp   =>0,
      :cpu_fan    =>0,
      :cpu_power  =>0,
      :threads_used =>0,
    })
  end
  
  def structure
    worker_structure
  end  

  # Try to clean up CPU text ...
  def cpu_clean(cpu)
    cpu.gsub!(/\(.+\)|\@|Processor|\s$/,'')
    cpu.gsub!(/\s+/,' ')
    cpu.gsub!(/$\s/,'')
    cpu.chomp!
    cpu.chomp!
    cpu
  end

  # Take uptime in seconds and convert to d/h/m format
  #
  def uptime_seconds(time)
    time = time.to_f
    if time > 86400
      sprintf("%.2fd",(time / 86400))
    elsif time > 3600
      sprintf("%.2fh",(time / 3600))
    else
      sprintf("%.2fm",(time / 60))
    end
  end

  # Take uptime in minutes and convert to d/h/m format
  #
  def uptime_minutes(time)
    uptime_seconds(time.to_f * 60)
  end
  
  # Output a console table
  def table_out(headers,rows,title=nil)
    max_col = 0
    rows.each {|row|
      max_col = row.count if row.count > max_col
    } 

    div = "│" #colorize("│",$color_divider)
    table = Terminal::Table.new do |t|
      t.headings = headers
      t.style = {
        :border_left => false, :border_right => false,
        :border_top => false, :border_bottom => false,
        :border_y => div,
        :padding_left => 0, :padding_right => 0,
        :border_x =>"─" , :border_i => "┼",
      }      
      if standalone?
        t.style.width = 60
      end
      t.title = title if title
    end

    rows.each {|r|
      if r.count < max_col
        (max_col - r.count).times {|i| r << ''}
      end
      table << r.map{|c|
        colorize(c,$color_row)        
      }
    }

    # Go thru all columns to set alignment because setting it
    # in new overrides individual columns
    table.columns.count.times{|col|
      ori = col == 0 ? :left : :right
      table.align_column(col, ori)
    }
    
    tout = table.render
    tarr = tout.split("\n")
    idx = 0
    len = tarr[1].length + 1

    if title
      tarr.delete_at(idx + 1)
      tarr[idx] = colorize( sprintf("%-#{len}s",tarr[idx]),$color_standalone_title)
      idx = idx + 1
    end
    tarr.delete_at(idx + 1)
    tarr[idx].gsub!(/[\||\│]/,' ')
    tarr[idx] = no_colors(tarr[idx])
    diff = len - tarr[idx].length
    tarr[idx] = colorize("#{tarr[idx]}#{' '*diff}",$color_header)
    tarr.map!{|t|
      t.gsub("│",colorize("│",$color_divider))
    }
    tout = tarr.join("\n") << "\n \n"    
  end

  def colorize(val,colors)
    m = $pastel
    arc = *colors
    #pp colors
    arc.each {|c|
      m = m.send(c)
    }
    m.detach.(val)
  end
  
  def no_colors(s)
    s.gsub /\e\[\d+m/, ""
  end

  
end
