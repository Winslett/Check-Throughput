require 'rubygems'
require 'snmp'
require 'lib/router'

Given /^a router named ([a-z\-]+) with ([0-9]+) interface[s]?$/ do | name, num_interfaces |
  interfaces = (1..num_interfaces.to_i).to_a
  @router = Router.new(:name => name, :interfaces => interfaces)
end

Given /^a router named ([a-z\-]+) using interface ([0-9]+) at ([^\ ]+)$/ do | name, interface, ip_address |
  interfaces = [interface.to_i]
  @router = Router.new(:name => name, :interfaces => interfaces, :ip_address => ip_address)
end

Given /probing the ([0-9]+)[a-z]+ interface/ do | interface |
  @interface = interface.to_i
end

Given /^request counters$/ do
  @router.get_counters
end

Given /wait ([0-9]+) seconds/ do | seconds |
  Kernel.sleep(seconds.to_i)
end

Given /^previous (in|out) counter of ([0-9]+)$/ do | direction, counter |
  @direction = direction
  @router.send("#{@direction}_counters")[@interface] = [counter.to_i]
end

Given /^occurred ([0-9]+) seconds ago$/ do | seconds |
  @router.send("#{@direction}_times")[@interface] = [Time.now - seconds.to_i]
end

Given /^a new (in|out) counter of ([0-9]+)$/ do | direction, counter |
  @router.send("add_counter", {:interface => @interface, :direction => direction, :counter => counter.to_i})
end

Then /^should respond with an ([a-z]+) throughput of ([0-9]+)$/ do | direction, throughput |
  raise "NOT EQUAL! #{throughput.to_i} and #{@router.send("throughput", {:interface => @interface, :direction => direction})}" if throughput.to_i != @router.send("throughput", {:interface => @interface, :direction => direction}).round
end

Given /^new (in|out) counter is added$/ do | direction |
  @router.send("add_counter", {:interface => @interface, :counter => (Kernel.rand.to_i).floor, :direction => direction})
end

Given /^(in|out) counter contains ([0-9]+) reading[s]?$/ do | direction, readings |
  1.upto(readings.to_i) do | i |
    @router.send("add_counter", {:interface => @interface, :direction => direction, :counter => i})
  end
end

Then /^should contain ([0-9]+) (in|out) reading[s]?$/ do | readings, direction |
  raise "NOT EQUAL! #{readings.to_i} and #{@router.send("#{direction}_counters")[@interface].length}" if readings.to_i != @router.send("#{direction}_counters")[@interface].length
end

Then /^should reply with valid (in|out) throughput on interface ([0-9]+)$/ do | direction, interface |
  interface = interface.to_i
  raise "NOT VALID! #{@router.throughput(:direction => direction, :interface => interface)}" if !(@router.throughput(:direction => direction, :interface => interface) > 0)
end
