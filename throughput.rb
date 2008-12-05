#!/usr/bin/ruby

require 'rubygems'
require 'snmp'
require 'lib/router'

port = 2000

require 'socket'

@routers = [Router.new(:ip_address => "10.205.5.2", :name => "bhm-rtr-wan", :interfaces => [1]),
            Router.new(:ip_address => "10.205.5.2", :name => "bhm-rtr-wan", :interfaces => [1])]

Thread.new do
  loop do
    @routers.each { | router | router.get_counters }
    sleep(10)
  end
end

TCPServer.open(port) do | s |
  loop do
    Thread.start(s.accept) do | client |
      begin
        while t = client.gets
          begin
            if t.strip =~ /^([^\ ]+)\ ([0-9]+)\ (in|out)$/ 
               ip_address, interface, direction = $1, $2.to_i, $3 
               router = @routers.find { | router | router.ip_address == ip_address }
              raise "Could not find device by ip address" if router.nil?
              client.puts(router.throughput(:direction => direction, :interface => interface))
            else
              raise "INVALID FORMAT: [ip_address] [interface] [direction]"
            end
          rescue Exception => e
            client.puts e.to_s
          end
        end
      ensure
        client.close
      end
    end
  end
end
