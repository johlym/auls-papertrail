################################################################################
#                                                                              #
# Axe                                                                          #
# A simple FIFO AULS relay for macOS 10.12 and Papertrail                      #
#                                                                              #
################################################################################

require 'pty'
require 'socket'
require 'thread'
require 'yaml'

#TODO: Parse the YAML file and loads its values into the ivars below

## The config ##

@remote_host = "logs5.papertrailapp.com"
@remote_port = 36763
@hostname = Socket.gethostname

## Generate the Queue ##
@queue = Queue.new

## Set up the regex for parsing the AULS stream ##

@parser = /^(\S*)\s(\S*)\s*(\S*)\s*(\S*):\s(.*)$/

## Suck in logs from AULS ##

def consumption
  # Generate the Queue

  cmd = "log stream --style=syslog --level=debug"
  begin
    PTY.spawn( cmd ) do |stdout, stdin, pid|
      begin
        # Do stuff with the output here. Just printing to show it works
        stdout.each do |line|
          @queue.push(line)
        end
      rescue Errno::EIO
        puts "Errno:EIO error, but this probably just means " +
              "that the process has finished giving output"
      end
    end
  rescue PTY::ChildExited
    puts "The child process exited!"
  end
end

## Push logs to Papertrail ##

def production
  puts "Creating a connection"
  puts "Generating socket"

  # Open a Connection
  begin
    sender = TCPSocket.new(@remote_host, @remote_port)
  rescue Errno::ECONNREFUSED
    client_socket.close
    raise
  end
  puts "Socket generated"

  # Get the oldest message in the queue
  while true
    begin
      # start_time = Time.now
      message = @queue.pop

      # Make sure it fits the format we're expecting
      if matched = message.match(@parser)
        _, datestamp, timestamp, reported_hostname, process, message = *matched

        # Omit the timezone offset since it's formattted incorrectly.
        timestamp = timestamp[0...-5]
        tz_offset = Time.now.strftime '%:z'
        date_and_timestamp = "#{datestamp}T#{timestamp}#{tz_offset}"
        # date_and_timestamp = Time.now.strftime '%Y-%m-%dT%H:%M:%S%:z'

        # Convert the log line into a legitimate syslog format
        formatted = "<14>1 #{date_and_timestamp} #{@hostname} #{process} - - - #{message}\n"
      end

      # Write the log line out
      sender.write formatted

      # Flush
      # sender.flush
      # end_time = Time.now
      # puts "#{(end_time - start_time) * 1000}ms; Queue size: #{@queue.length}"
    rescue StandardError => e
      puts "Exception: #{e.inspect}"
    end
  end
end

## Start the threads ##

puts "Starting production thread"
Thread.new { production }

puts "Starting consumption thread"
Thread.new { consumption }

loop do
  # puts "Queue size: #{@queue.length}"
  sleep 1
  if @queue.length > 0
    puts "Logs not sending in real time; length: #{@queue.length}"
  end
  true
end
