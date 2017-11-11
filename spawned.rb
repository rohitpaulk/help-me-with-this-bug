require "./common"

# Prevent signals from automatically being forwarded
# Process.setpgrp
Process.setpgrp

parent = UNIXSocket.for_fd(3)

def receive_fd(socket)
  fd = socket.recv_io
  socket.puts # Acknowledgement

  fd
end

def receive_signal(socket)
  signal = socket.gets.chomp
  socket.puts

  puts "Received signal #{signal}. Applying to self".yellow

  Process.kill(signal, Process.pid) # Send to self
end

parent_stderr = receive_fd(parent)
parent_stdout = receive_fd(parent)
parent_stdin = receive_fd(parent)

parent.gets # Final acknowledgement

Thread.abort_on_exception = true
thr = Thread.new do
  loop do
    puts "Waiting for a signal in thread"
    receive_signal(parent)
  end
end

STDERR.reopen(parent_stderr)
STDOUT.reopen(parent_stdout)
STDIN.reopen(parent_stdin)

at_exit do
  STDERR.close
  STDOUT.close
  STDIN.close
end

puts "Hi from the spawned process!".yellow
puts

puts <<~MSG.yellow
  Let's first enter 3 lines normally, without hitting CTRL+z in the middle.
MSG

sleep 2
puts "HEY!"

puts "Calling gets"
STDIN.gets

# CommonFunctions.echo_input_back
