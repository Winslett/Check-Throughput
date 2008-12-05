class CheckThroughput
  attr_accessor :host, :interface, :direction, :throughput, :ranges

  def initialize(args)
    @host, @interface, @direction, @ranges = args[:host], args[:interface], args[:direction], args[:ranges]

    TCPSocket.open("127.0.0.1", "2000") { | client | client.puts "#{@host} #{@interface} #{@direction}"; @throughput = client.gets.to_f / 102.4 }
  end

  def critical?
    "THROUGHPUT CRITICAL: last measured at #{@throughput}" if check_warning(:critical)
  end

  def warning?
    "THROUGHPUT WARNING: last measured at #{@throughput}" if check_warning(:warning)
  end

  private
  def check_warning(level)
    !@ranges[level].nil? && (@ranges[level].begin > @throughput || @ranges[level].end < @throughput)
  end
end
