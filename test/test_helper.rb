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

    def trace(probe, trace: "\"TEST\"")
        finished = false
        fire_thread = Thread.new do
            until finished
                yield
                sleep 0.001
            end
        end

        #trace_output = IO.popen(['pkexec', '/usr/share/bcc/tools/trace',
        trace_output = IO.popen(['sudo', '/usr/share/bcc/tools/trace',
            '-p', Process.pid.to_s,
            '-M', '10', "u::#{probe.name} #{trace}"]) do |io|
                io.read
            end

        trace_result = $?

        finished = true
        fire_thread.value

        return trace_result, trace_output
    ensure
        finished = true
        fire_thread.value
    end

    def assert_trace(probe, trace: "\"FIRED\"", &block)
        trace_status, trace_output =
            trace(probe, trace: trace, &block)
        assert trace_status.success?, "trace failed"
        lines = trace_output.split("\n").find_all { |l| l =~ /FIRED/ }
        assert_equal 10, lines.size
        return trace_output
    end

    def run_traced(probe_name, cmd, *args, trace: '\"TEST\"')
        r, w = IO.pipe
        pid = Kernel.spawn(Gem.ruby, File.join(__dir__, 'scripts', cmd), *args, out: w)
        w.close
        r.each_line { |line| break if line =~ /ready/ }
        reader_thread = Thread.new { r.read }

        #trace_output = IO.popen(['pkexec', '/usr/share/bcc/tools/trace',
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
