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

            it "raises if attempting to create a probe with more than 6 arguments" do
                e = assert_raises(ArgumentError) do
                    @provider.add_probe("invalidProbe", *([Integer] * 10))
                end
                assert_equal "libstapstd only supports up to 6 arguments, got 10",
                    e.message
            end
        end

        describe "arguments passed directly" do
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

            (1..6).each do |arg_count|
                it "passes #{arg_count} arguments" do
                    probe = @provider.add_probe("testProbe", *[Integer]*arg_count)
                    @provider.load

                    trace_args = (1..arg_count).map do |i|
                        " arg#{i}"
                    end.join(", ")
                    trace = "\"FIRED#{" %d" * arg_count}\" #{trace_args}"
                    args = (2..arg_count).each_with_object([1]) do |_, array|
                        array << array.last * 2
                    end
                    trace_output, _ = assert_trace(probe, trace: trace) do
                        probe.fire(*args)
                    end

                    lines = trace_output.split("\n")
                    assert_match /FIRED #{args}/, lines[1]
                end
            end

            it "raises if attempting to pass a string for a numeric value" do
                probe = @provider.add_probe("testProbe", Integer)
                @provider.load
                e = assert_raises(TypeError) do
                    probe.fire("string")
                end
                assert_equal "no implicit conversion from string", e.message
            end

            it "raises if attempting to pass an arbitrary object for a numeric value" do
                probe = @provider.add_probe("testProbe", Integer)
                @provider.load
                e = assert_raises(TypeError) do
                    probe.fire(Object.new)
                end
                assert_equal "no implicit conversion of Object into Integer", e.message
            end

            it "raises if attempting to pass a numeric value for a string" do
                probe = @provider.add_probe("testProbe", String)
                @provider.load
                e = assert_raises(TypeError) do
                    probe.fire(10)
                end
                assert_equal "no implicit conversion of Integer into String", e.message
            end

            it "raises if attempting to pass an arbitrary object for a string" do
                probe = @provider.add_probe("testProbe", String)
                @provider.load
                e = assert_raises(TypeError) do
                    probe.fire(Object.new)
                end
                assert_equal "no implicit conversion of Object into String", e.message
            end

            it "raises if attempting to give less arguments than expected by the probe" do
                probe = @provider.add_probe("testProbe", Integer)
                @provider.load
                e = assert_raises(ArgumentError) do
                    probe.fire
                end
                assert_equal "expected 1 argument(s), got 0", e.message
            end

            it "raises if attempting to give more arguments than expected by the probe" do
                probe = @provider.add_probe("testProbe", Integer)
                @provider.load
                e = assert_raises(ArgumentError) do
                    probe.fire(10, 20)
                end
                assert_equal "expected 1 argument(s), got 2", e.message
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

        describe "arguments returned by a block" do
            it "does not call the block if the probe is not traced" do
                probe = @provider.add_probe("testProbe", Integer)
                @provider.load
                refute probe.fire { flunk("fire called the block") }
            end

            it "calls the block and uses the returned array" do
                probe = @provider.add_probe("testProbe", Integer)
                @provider.load

                trace_output, _ = assert_trace(probe, trace: "\"FIRED %d\" arg1") do
                    probe.fire { [42] }
                end
                output = trace_output.split("\n")[1]
                assert_match /FIRED 42/, output
            end
        end
    end
end
