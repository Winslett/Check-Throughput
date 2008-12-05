class Router
  attr_accessor :name, :interfaces, :ip_address, :out_counters, :out_times, :in_counters, :in_times

  def initialize(args)
    @name, @interfaces, @ip_address = args[:name], args[:interfaces], args[:ip_address]
    @out_counters, @out_times, @in_counters, @in_times = [], [], [], []
    args[:interfaces].each do | interface |
      @out_counters[interface], @out_times[interface], @in_counters[interface], @in_times[interface] = [], [], [], []
    end
  end

  def add_counter(args)
    counters, times = eval("@#{args[:direction]}_counters")[args[:interface]], eval("@#{args[:direction]}_times")[args[:interface]]
    counters << args[:counter]
    times << Time.now
    counters.shift && times.shift if counters.length > 20
  end

  def throughput(args)
    counters, times = eval("@#{args[:direction]}_counters")[args[:interface]], eval("@#{args[:direction]}_times")[args[:interface]]
    (counters.last - counters[counters.length - 2]) / (times.last - times[times.length - 2])
  end

  def get_counters
    SNMP::Manager.open(:Host => @ip_address, :Version => :SNMPv1, :Community => "see*me") do | snmp |
      @interfaces.each do | interface |
        ["in", "out"].each do | direction |
          snmp.get(["if#{direction.capitalize}Octets.#{interface}"]).each_varbind { | varbind | add_counter(:interface => interface, :direction => direction, :counter => varbind.value.to_f) }
        end
      end
    end
  end
end
