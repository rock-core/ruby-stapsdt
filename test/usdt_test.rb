require "test_helper"

module USDT
    describe Provider do
        it "defines a single probe without arguments" do
            assert_runs("probe_without_arguments", "100")
        end
        it "successfully traces a single probe without arguments" do
            assert_runs_traced('testProbe', 'probe_without_arguments')
        end
        it "reports probes that are watched as enabled" do
            _, output = assert_runs_traced('testProbe', 'probe_without_arguments')
            assert_match /enabled/, output
        end
        it "returns true in #fire if the probe is enabled" do
            _, output = assert_runs_traced('testProbe', 'probe_without_arguments')
            assert_match /fired/, output
        end
        it "does not report probes that are not watched as enabled" do
            output = assert_runs('probe_without_arguments', "100")
            refute_match /enabled/, output
        end
        it "returns false in #fire if the probe is not enabled" do
            output = assert_runs('probe_without_arguments', '100')
            refute_match /fired/, output
        end

        it "passes numeric arguments specified with the ARG constants" do
            trace_output, output = assert_runs_traced(
                'testProbe', 'probe_raw_arguments',
                trace: "\"FIRED %d %d\" arg1, arg2")
            lines = trace_output.split("\n")
            capture = lines.map do |l|
                if l =~ /FIRED (\d+) (\d+)$/
                    [Integer($1), Integer($2)]
                end
            end.compact
            assert capture.size > 2
            capture.each { |i, j| assert_equal i, j + 100 }
            capture.each_cons(2) do |(i0, j0), (i1, j1)|
                assert_equal i1, i0 + 1
                assert_equal j1, j0 + 1
            end
        end

        it "passes Float arguments" do
            trace_output, output = assert_runs_traced(
                'testProbe', 'probe_float_argument', '0.1',
                trace: "\"FIRED %llu\" arg1")
            lines = trace_output.split("\n")
            assert(m = /FIRED (\d+)$/.match(lines[1]))
            assert_equal [0.1], [Integer(m[1])].pack("Q").unpack("D")
        end

        it "passes String arguments" do
            trace_output, output = assert_runs_traced(
                'testProbe', 'probe_string_argument', 'this is a test string',
                trace: "\"FIRED %s\" arg1")
            lines = trace_output.split("\n")
            assert(m = /FIRED (.*)$/.match(lines[1]))
            assert_equal "this is a test string", m[1]
        end
    end
end
