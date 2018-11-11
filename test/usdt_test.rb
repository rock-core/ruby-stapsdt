require "test_helper"

module USDT
    describe Provider do
        before do
            @provider = USDT::Provider.new("test")
        end

        after do
            @provider.unload if @provider.loaded?
        end

        describe "probe definition" do
            before do
                @probe = @provider.add_probe("testProbe")
                @provider.load
            end
            it "returns false in #fire if the probe is not enabled" do
                refute @probe.fire
            end
            it "returns the probe name" do
                assert_equal 'testProbe', @probe.name
            end
            it "reports that the probe is not enabled" do
                refute @probe.enabled?
            end
            it "successfully traces the probe" do
                assert_trace(@probe) { @probe.fire }
            end
            it "reports a traced probe as enabled" do
                success = false
                assert_trace(@probe) do
                    success ||= @probe.enabled?
                    @probe.fire
                end
                assert success
            end
            it "returns true in #fire if the probe is enabled" do
                success = false
                assert_trace(@probe) do
                    success = true if @probe.fire
                end
                assert success
            end
        end

        it "passes numeric arguments specified with the ARG constants" do
            probe = @provider.add_probe("testProbe", USDT::ARG_UINT32, USDT::ARG_UINT64)
            @provider.load
            i = 0
            trace_output, _ = assert_trace(probe, trace: "\"FIRED %d %d\" arg1, arg2") do
                probe.fire(i + 100, i)
                i += 1
            end

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
            probe = @provider.add_probe("testProbe", Float)
            @provider.load

            trace_output, _ = assert_trace(probe, trace: "\"FIRED %llu\" arg1") do
                probe.fire(0.1)
            end

            lines = trace_output.split("\n")
            assert(m = /FIRED (\d+)$/.match(lines[1]))
            assert_equal [0.1], [Integer(m[1])].pack("Q").unpack("D")
        end

        it "passes String arguments" do
            probe = @provider.add_probe("testProbe", String)
            @provider.load

            trace_output, _ = assert_trace(probe, trace: "\"FIRED %s\" arg1") do
                probe.fire('this is a test string')
            end

            lines = trace_output.split("\n")
            assert(m = /FIRED (.*)$/.match(lines[1]))
            assert_equal "this is a test string", m[1]
        end
    end
end
