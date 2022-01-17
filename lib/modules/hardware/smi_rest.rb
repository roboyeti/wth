# Author: BeRogue01
# License: See LICENSE file
# Date: 10/2021
#
# java -jar file.jar --server.port=<port>
# 
class Modules::SmiRest < Modules::Base
   
  def initialize(p={})
    super
    @title = "Nvidia SMI-Rest"
    @port = @config["port"] || 8176
    @headers = [
      'Name','Device','Type','Bus/Id','Bios/Cores','Driver Version','Mem(GB)','Mem Free(GB)','Pwr(W)','Temp','Fan%','Clk','MemClk','CoreLoad','MemLoad'
    ]
  end
  
  def check(val,key)
    res = simple_rest("http://#{val}:#{port}/v1")
    format(val,key,res)
  end

  def format(val,key,rdata)
    o = HostStructure.new #node_structure
    o.name = key
    o.address = val
    gpu = {}

    rdata["gpu"].each_with_index{|gv,idx|
      g = GpuDevice.new
      g.name = gv["productName"]
      g.manufacturer = gv["productName"].split(" ")[0]
      g.id = idx
      g.pci = gv["pci"]["pciBus"].to_i
      g.location = gv["pci"]["pciBusId"]
      g.bios = gv["vbiosVersion"]
      g.driver = rdata["driverVersion"]
      g.memory_free = gv["fbMemoryUsage"]["free"].to_f / 1000
      g.memory_used = gv["fbMemoryUsage"]["used"].to_f / 1000
      g.memory_total = gv["fbMemoryUsage"]["total"].to_f / 1000
      g.temperature = gv["temperature"]["gpuTemp"].to_i
      g.power = gv["powerReadings"]["powerDraw"].split(" ")[0].to_i
      g.fan_percent = gv["fanSpeed"].to_i
      g.clock = gv["clocks"]["smClock"].to_i
      g.memory_clock = gv["clocks"]["memClock"].to_i
      g.core_load = gv["utilization"]["gpuUtil"].to_i
      g.memory_load = gv["utilization"]["memoryUtil"].to_i
      g.pci_rx = gv["pci"]["rxUtil"].split(" ")[0].to_f / 1000
      g.pci_tx = gv["pci"]["txUtil"].split(" ")[0].to_f / 1000
      gpu[g.id.to_s] = g
    }
    o.gpu = gpu
    o
  end

  def tableize(data)
    tables = []
    tables << super(data) do |item,rows,formats|
      item.gpu.each_pair{|k,g|
        rows << [
          item.name.capitalize,
          g.name, g.type,
          g.pci, g.bios, g.driver, g.memory_total.round, g.memory_free, g.power,
          g.temperature, g.fan_percent,
          g.clock, g.memory_clock, g.core_load, g.memory_load
        ]
        formats << [ nil,[:bright_cyan],[:bright_cyan],nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil ]
      }
    end
    tables
  end

  def node_structure
    HostStructure.new
  end

end