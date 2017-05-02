# cribbed code from http://blog.bitmelt.com/2010/01/transparent-tcp-proxy-in-ruby-jruby.html

require "socket"

remote_host = "logs5.papertrailapp.com"
remote_port = 36763
listen_port = 60514
max_threads = 100
threads = []

PARSER = /^(\S*)\s(\S*)\s*(\S*)\s*(\S*):\s(.*)$/
HOSTNAME = "unified-logging"

puts "starting server"
server = TCPServer.new(nil, listen_port)
while true
  # Start a new thread for every client connection.
  puts "waiting for connections"
  threads << Thread.new(server.accept) do |client_socket|
    begin
      puts "#{Thread.current}: got a client connection"
      begin
        server_socket = TCPSocket.new(remote_host, remote_port)
      rescue Errno::ECONNREFUSED
        client_socket.close
        raise
      end
      puts "#{Thread.current}: connected to server at #{remote_host}:#{remote_port}"

      while true
        # Wait for data to be available on either socket.
        (ready_sockets, dummy, dummy) = IO.select([client_socket, server_socket])
        begin
          ready_sockets.each do |socket|
            data = socket.readpartial(8192)
            if socket == client_socket
              # Read from client, write to server.
              if data && data.length > 0
                if matched = data.match(PARSER)
                  _, datestamp, timestamp, localhostname, process, message = *matched
                  date_and_timestamp = Time.now.strftime '%Y-%m-%dT%H:%M:%S%:z'
                  rewritten = "<14>1 #{date_and_timestamp} #{HOSTNAME} #{process} - - - #{message}\n"
                  puts rewritten
                end
              end
              server_socket.write rewritten
              server_socket.flush
            else
              # Read from server, write to client.
              puts "#{Thread.current}: server->client #{data.inspect}"
              client_socket.write data
              client_socket.flush
            end
          end
        rescue EOFError
          break
        end
      end
    rescue StandardError => e
      puts "Thread #{Thread.current} got exception #{e.inspect}"
    end
    puts "#{Thread.current}: closing the connections"
    client_socket.close rescue StandardError
    server_socket.close rescue StandardError
  end

  # Clean up the dead threads, and wait until we have available threads.
  puts "#{threads.size} threads running"
  threads = threads.select { |t| t.alive? ? true : (t.join; false) }
  while threads.size >= max_threads
    sleep 1
    threads = threads.select { |t| t.alive? ? true : (t.join; false) }
  end
end
