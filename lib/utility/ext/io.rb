# @project Misc Ruby Utility
# @author B.Rogue
# @license So free, it is scared of it's own freedom.
#
# Quick and dirty "non-blocking"-ish read of socket
# mashed in a cruel and unfriendly way of monkey
# patch to Ruby.
#
# Use:
#   load or require it, as is appropriate.
#
class IO
  def readline_nonblock
    buffer = ""
    buffer << read_nonblock(1) while buffer[-1] != "\n"

    buffer
  rescue IO::WaitReadable => blocking
    raise blocking if buffer.empty?

    buffer
  end
end
