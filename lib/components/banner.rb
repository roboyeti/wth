# Author: BeRogue01
# License: See LICENSE file
# Date: 2022/02
#
class Banner
  using IndifferentHash  

  def self.says(text,width=120,align="center",colors=[])
    self.new("width" => width, "align" => align, "colors" => colors).console_out(text)
  end

  def initialize(p={})
    @config = p
    @width = @config["width"] || 120
    @width -= 4
    @align = @config["align"] || "left"
    @color = if @config["colors"]
      @config["colors"].map(&:to_sym)
    else
      [:yellow,:on_magenta,:dim]
    end  
  end

  def console_out(text)
    rtext = if @align == "center"
      text.center(@width)
    elsif @align == "right"
      text.rjust(@width)
    else
      text.ljust(@width)
    end
    colorit("⯈ #{rtext} ⯇",@color)
  end

  def colorize(val,colors)
    m = Pastel.new
    arc = *colors
    arc.each {|c|
      m = m.send(c)
    }
    m.detach.(val)
  rescue
    val
  end
  alias_method :colorit, :colorize

end
