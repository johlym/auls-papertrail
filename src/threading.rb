# Threading tests

require 'socket'

listen_port = 60515

# Start TCP server
server = TCPServer.new(nil, listen_port)

while true
  # The Receiver
  threads << Thread.new(server.accept) do |client_socket|

  end



end
