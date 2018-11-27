require "stapsdt/version"
require "stapsdt/stapsdt"
require "stapsdt/provider"
require "stapsdt/probe"

# Runtime definition of StapSDT (Dtrace) probes on Linux
#
# To use, create a {StapSDT::Provider} instance, define probes with
# {StapSDT::Provider#add_probe}. Once the provider is loaded with {Provider#load},
# the StapSDT probes are available to tracing tools such as bcc's tplist and
# trace. Within the program, the {Probe} objects returned by add_probe can be
# fired with {Probe#fire}.
module StapSDT
    ARG_UINT8 = 1
    ARG_INT8 = -1
    ARG_UINT16 = 2
    ARG_INT16 = -2
    ARG_UINT32 = 4
    ARG_INT32 = -4
    ARG_UINT64 = 8
    ARG_INT64 = -8
end

