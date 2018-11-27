require 'stapsdt'

puts "PID: #{Process.pid}"

provider = StapSDT::Provider.new('example')

probe = provider.add_probe("test", String, Integer)
provider.load

i = 0
loop do
    probe.fire("some string", i += 1)
end
