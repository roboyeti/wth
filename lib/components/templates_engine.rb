require 'erb'
require "terminal"

def html_basic_page(width,out)
  contents = Terminal.render(out.join("\n"))

  # TODO - load from file, allowing it to be updated while program is running
  template = ERB.new(%Q{
  <pre class="term-outer">
    <pre class="term-container"><%= contents %></pre>
  </pre>
    })                   
# file_data = File.read("template_html.erb").split)
  template.result(binding)
end
