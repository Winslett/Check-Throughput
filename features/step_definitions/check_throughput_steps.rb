require 'socket'
require 'lib/check_throughput'

Given /^the throughput process is running$/ do
  begin
    TCPSocket.open("127.0.0.1", "2000") do | tcp |
    end
  rescue Exception => e
    fork { exec("ruby throughput.rb") }
  end
end

Given /^host is ([^\ ]+)$/ do | ip_address |
  @host = ip_address
end

Given /^interface is the ([0-9]+)[a-z]+$/ do | interface |
  @interface = interface
end

Given /^traffic is going (in|out)$/ do | direction |
  @direction = direction
end

Given /^a Nagios request is made$/ do
  @check_throughput = CheckThroughput.new(:host => @host, :interface => @interface, :direction => @direction, :ranges => @ranges)
end

Given /^a (critical|warning) range of ([0-9]+) and ([0-9]+)$/ do | type, low, high |
  @ranges ||= {}
  @ranges[type.to_sym] = (low.to_i..high.to_i)
end

Given /^should respond with a valid throughput$/ do 
  raise "NOT VALID! #{@check_throughput.throughput}" if !(@check_throughput.throughput > 0)
end

Then /^should format throughput to KB\/s$/ do
  raise "NOT VALID! #{@check_throughput.formatted_throughput}" if @check_throughput.formatted_throughput =~ /[^kb\/s]$/
end

Then /^should be critical$/ do
  raise "NOT CRITICAL!" if !@check_throughput.critical?
end

Then /^should have a warning$/ do
  raise "NOT WARNING!" if !@check_throughput.warning?
  raise "HAS CRITICAL!" if @check_throughput.critical?
end

Then /^should not have a warning$/ do
  raise "HAS WARNING!" if @check_throughput.warning?
  raise "HAS CRITICAL! #{@check_throughput.critical?}" if @check_throughput.critical?
end
