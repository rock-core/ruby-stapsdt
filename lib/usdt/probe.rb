module USDT
    # A single USDT probe
    #
    # Probe objects are exclusively created with {Provider#add_probe}
    class Probe
        private_class_method :new

        # @!method fire(*args)
        #
        # @param [Array] args arguments matching the types defined when
        #   the probe was created

        # @!method enabled?
        #
        # Whether the probe is being traced
    end
end
