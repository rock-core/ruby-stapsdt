$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "usdt"

require "minitest/spec"
require "minitest/autorun"

module Helpers
    def assert_runs(cmd, *args)
        output = IO.popen([Gem.ruby, File.join(__dir__, 'scripts', cmd), *args]) do |io|
            io.read
        end
        assert($?.success?)
        output
    end
    def run_traced(probe_name, cmd, *args, trace: '\"TEST\"')
        r, w = IO.pipe
        pid = Kernel.spawn(Gem.ruby, File.join(__dir__, 'scripts', cmd), *args, out: w)
        w.close
        r.each_line { |line| break if line =~ /ready/ }
        reader_thread = Thread.new { r.read }
        trace_output = IO.popen(['sudo', '/usr/share/bcc/tools/trace',
            '-p', pid.to_s, '-M', '10', "u::testProbe #{trace}"]) do |io|
            io.read
        end
        Process.kill 'KILL', pid
        pid = nil
        return $?, trace_output, reader_thread.value
    ensure
        Process.kill('KILL', pid) if pid
    end

    def assert_runs_traced(probe_name, cmd, *args, trace: "\"FIRED\"")
        trace_status, trace_output, output =
            run_traced(probe_name, cmd, *args, trace: trace)
        assert trace_status.success?, "trace failed"
        lines = trace_output.split("\n").find_all { |l| l =~ /FIRED/ }
        assert_equal 10, lines.size
        return trace_output, output
    end
end

Minitest::Test.include Helpers
