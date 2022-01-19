# Author: BeRogue01
# License: See LICENSE file
# Date: 2022/01
#
class Modules::Banner < Modules::Base
  using IndifferentHash  

  def initialize(p={})
    super
    @text = @config["text"]
    @width = @config["width"] || 120
    @width -= 4
    @align = @config["align"] || "left"
    @color = if @config["colors"]
      @config["colors"].map(&:to_sym)
    else
      $color_banner
    end  
  end

  def check_all
    @data[:text] = @text
  end

  def console_out(data=@data)
    text = if @align == "center"
      @text.center(@width)
    elsif @align == "right"
      @text.rjust(@width)
    else
      @text.ljust(@width)
    end
    colorit("⯇ #{text} ⯈",@color)
  end
end
