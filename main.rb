require "./common"

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

puts "Ready? (press ENTER)".green
STDIN.gets

# Spawn process
# Forward signals
# Hand over IO objects.
