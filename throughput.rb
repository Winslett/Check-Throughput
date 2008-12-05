#!/usr/bin/ruby

require 'rubygems'
require 'snmp'
require 'lib/router'

port = 2000

require 'socket'

@routers = []

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
              if router.nil?
                @routers << Router.new(:ip_address => ip_address, :interfaces => [interface])
              else
                if @routers.interfaces.index(interface)
                  client.puts(router.throughput(:direction => direction, :interface => interface))
                else
                  @router.interfaces << interface
                end
              end
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
