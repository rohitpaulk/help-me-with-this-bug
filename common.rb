require "bundler"
Bundler.require(:default)

require 'socket'

module CommonFunctions
  def self.echo_input_back
    3.times.each { puts "Received '#{STDIN.gets.strip}'".green }
    puts
  end
end
