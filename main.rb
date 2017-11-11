require "./common"

def print_intro!
  puts <<~MSG.blue
    Hi there!

    This bug relates to how reading from STDIN is interrupted when a process
    is paused (backgrounded?).

  MSG

  puts <<~MSG.blue
    Let's start with a simple example. Try typing out 3 lines of text. This
    program will emit a message for each.
  MSG

  CommonFunctions.echo_input_back

  puts <<~MSG.blue
    Now, try backgrounding the process in the middle. Enter one line, and then
    press CTRL+z to send the process to the background. Resume the process after,
    and enter the remaining lines.
  MSG

  CommonFunctions.echo_input_back

  puts <<~MSG.blue
    Great, that worked too!

    ------------------------------------

    Now, the fun part.

    - This process is going to spawn another process that runs the exact
      same code to echo input back.
    - It's going to send it's STDIN & STDOUT to the forked process via a Unix
      domain socket.
    - It's also going to forward all unix signals received to the spawned process.
      This ensures that the signal to place the process in the background will
      be received by both this process and the spawned process.

  MSG
end

print_intro! unless ARGV[0] == "skip_intro"

puts "Ready? (press ENTER)".green
STDIN.gets

our_end, their_end = UNIXSocket.pair
pid = Process.spawn("ruby ./spawned.rb", 3 => their_end)

# Forward signals

def send_fd(socket, name, fd)
  puts "Sending #{name} to the spawned process".blue
  socket.send_io(fd)
  socket.gets
end

send_fd(our_end, "STDERR", STDERR)
send_fd(our_end, "STDOUT", STDOUT)
send_fd(our_end, "STDIN", STDIN)

def forward_signal(signal, socket)
  socket.puts(signal)
  socket.gets # Ack
end

def forward_and_apply(signal, socket)
  trap(signal) {
    puts "Forwarding signal #{signal}!".blue
    forward_signal(signal, socket)

    puts "Applying signal to self #{signal}!".blue
    trap(signal, "DEFAULT")
    Process.kill(signal, Process.pid)

    forward_and_apply(signal, socket)
  }
end

signals_to_forward_and_apply = %w(TSTP CONT)
signals_to_forward_and_apply.each do |signal|
  forward_and_apply(signal, our_end)
end

puts
puts "Okay! Handing over control. See you once the spawned process exits".blue
puts
our_end.puts

def is_alive?(pid)
  begin
    Process.kill(0, pid)
    true
  rescue Errno::ESRCH
    false
  end
end

loop do
  puts "Has not exited"
  sleep 0.5
  break unless is_alive?(pid)
end

puts "Child process exited!".blue
