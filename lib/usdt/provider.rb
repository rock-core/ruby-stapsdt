module USDT
    # Collection of probes that can be activated and deactivated
    #
    # Providers are the entry point for probe definition
    #
    # After creation, probes are added with {#add_probe} and then
    # activated with {#load}. Probes can only be defined before the
    # provider gets loaded.
    class Provider
        class StateError < RuntimeError; end

        def initialize
            @loaded = false
        end

        # Whether this provider has been loaded
        def loaded?
            @loaded
        end

        private :load_c, :unload_c, :add_probe_c

        # Load the provider
        #
        # @raise [StateError] if the provider was already loaded. Call
        #   {#unload} first in this case
        def load
            raise StateError, "already loaded, call #unload first" if loaded?

            load_c
            @loaded = true
        end

        # Unloads the provider
        #
        # Does nothing if the provider was not yet loaded
        def unload
            return unless loaded?

            unload_c
            @loaded = false
        end

        # Add a new probe to this provider
        #
        # Probes must be added before the provider is loaded. Call {#unload} to
        # add new probes to an already-loaded provider
        #
        # @param [String] probe_name the name of the probe
        # @param [Array] arg_types the type of probe arguments.
        #   It is either one of the ARG_ constants defined within {USDT},
        #   or one of the Integer, Float and String classes.
        # @return [Probe]
        # @raise [StateError] if the provider was already loaded
        def add_probe(probe_name, *arg_types)
            if loaded?
                raise StateError, "already loaded, call #unload before adding new probes"
            end
            add_probe_c(probe_name, *arg_types)
        end
    end
end
