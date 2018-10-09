#include "usdt.h"

VALUE rb_mProvider;
VALUE rb_mProbe;
VALUE rb_mUsdt;

typedef struct Provider
{
    SDTProvider_t* provider;
} Provider_t;

typedef struct Probe
{
    SDTProbe_t* probe;
} Probe_t;

void provider_free(Provider_t* wrap)
{
    providerDestroy(wrap->provider);
    xfree(wrap);
}

VALUE provider_new(VALUE self, VALUE _name)
{
    char const* name = StringValuePtr(_name);
    SDTProvider_t* provider = providerInit(name);
    if (!provider)
        rb_raise(rb_eRuntimeError, "could not create provider with name %s", name);

    Provider_t* wrap = ALLOC(Provider_t);
    wrap->provider = provider;
    return rb_data_object_wrap(rb_mProvider, wrap, NULL, (RUBY_DATA_FUNC)provider_free);
}

void interpretError(int result, Provider_t* wrap)
{
    if (result != -1)
        return;

    if (wrap->provider->errno == noError)
        return;

    rb_raise(rb_eRuntimeError, "%s", wrap->provider->error);
}

VALUE provider_load(VALUE self)
{
    Provider_t* wrap;
    Data_Get_Struct(self, Provider_t, wrap);
    int result = providerLoad(wrap->provider);
    interpretError(result, wrap);
    return Qnil;
}

VALUE provider_unload(VALUE self)
{
    Provider_t* wrap;
    Data_Get_Struct(self, Provider_t, wrap);
    int result = providerUnload(wrap->provider);
    interpretError(result, wrap);
    return Qnil;
}

VALUE provider_add_probe(int argc, VALUE* argv, VALUE self)
{
    int args[MAX_ARGUMENTS];
    if (argc < 1)
        rb_raise(rb_eArgError, "expected at least one argument");
    if (argc > MAX_ARGUMENTS + 1)
        rb_raise(rb_eArgError,
            "libstapstd only supports up to %i arguments", MAX_ARGUMENTS);

    for (int i = 0; i < argc - 1; ++i)
        args[i] = NUM2INT(argv[i + 1]);

    Provider_t* wrap;
    Data_Get_Struct(self, Provider_t, wrap);

    SDTProbe_t* probe = NULL;
    if (argc == 1)
        probe = providerAddProbe(wrap->provider, StringValuePtr(argv[0]), 0);
    else if (argc == 2)
        probe = providerAddProbe(wrap->provider, StringValuePtr(argv[0]), 1,
            (ArgType_t)args[0]);
    else if (argc == 3)
        probe = providerAddProbe(wrap->provider, StringValuePtr(argv[0]), 2,
            (ArgType_t)args[0], (ArgType_t)args[1]);
    else if (argc == 4)
        probe = providerAddProbe(wrap->provider, StringValuePtr(argv[0]), 3,
            (ArgType_t)args[0], (ArgType_t)args[1], (ArgType_t)args[2]);
    else if (argc == 5)
        probe = providerAddProbe(wrap->provider, StringValuePtr(argv[0]), 4,
            (ArgType_t)args[0], (ArgType_t)args[1], (ArgType_t)args[2],
            (ArgType_t)args[3]);
    else if (argc == 6)
        probe = providerAddProbe(wrap->provider, StringValuePtr(argv[0]), 5,
            (ArgType_t)args[0], (ArgType_t)args[1], (ArgType_t)args[2],
            (ArgType_t)args[3], (ArgType_t)args[4]);
    else if (argc == 7)
        probe = providerAddProbe(wrap->provider, StringValuePtr(argv[0]), 6,
            (ArgType_t)args[0], (ArgType_t)args[1], (ArgType_t)args[2],
            (ArgType_t)args[3], (ArgType_t)args[4], (ArgType_t)args[5]);

    if (!probe)
        rb_raise(rb_eArgError, "failed to create probe");

    Probe_t* probe_wrap = ALLOC(Probe_t);
    probe_wrap->probe = probe;
    /* NOTE: probes cannot be deallocated. They're freed when the provider is */
    return rb_data_object_wrap(rb_mProbe, probe_wrap, NULL, NULL);
}

VALUE probe_fire(int argc, VALUE* argv, VALUE self)
{
    uint64_t args[MAX_ARGUMENTS];
    if (rb_block_given_p()) {
        if (argc != 0)
        {
            rb_raise(rb_eArgError, "cannot provide arguments "\
                "and block at the same time");
        }

        VALUE block_args = rb_yield_values(0);
        if (!NIL_P(block_args)) {
            argc = RARRAY_LEN(block_args);
            for (int i = 0; i < argc; ++i)
                args[i] = NUM2ULL(rb_ary_entry(self, i));
        }
    }
    else {
        for (int i = 0; i < argc; ++i)
            args[i] = NUM2ULL(argv[i]);
    }

    Probe_t* wrap;
    Data_Get_Struct(self, Probe_t, wrap);

    if (argc == 0)
        probeFire(wrap->probe);
    if (argc == 1)
        probeFire(wrap->probe, args[0]);
    if (argc == 2)
        probeFire(wrap->probe, args[0], args[1]);
    if (argc == 3)
        probeFire(wrap->probe, args[0], args[1], args[2]);
    if (argc == 4)
        probeFire(wrap->probe, args[0], args[1], args[2], args[3]);
    if (argc == 5)
        probeFire(wrap->probe, args[0], args[1], args[2], args[3], args[4]);
    if (argc == 6)
        probeFire(wrap->probe, args[0], args[1], args[2], args[3], args[4], args[5]);

    return probeIsEnabled(wrap->probe) ? Qtrue : Qfalse;
}

VALUE probe_enabled_p(VALUE self)
{
    Probe_t* wrap;
    Data_Get_Struct(self, Probe_t, wrap);
    return probeIsEnabled(wrap->probe) ? Qtrue : Qfalse;
}

void
Init_usdt(void)
{
    rb_mUsdt = rb_define_module("USDT");
    rb_mProvider = rb_define_class_under(rb_mUsdt, "Provider", rb_cObject);
    rb_define_singleton_method(rb_mProvider, "new", provider_new, 1);
    rb_define_method(rb_mProvider, "add_probe", provider_add_probe, -1);
    rb_define_method(rb_mProvider, "load", provider_load, 0);
    rb_define_method(rb_mProvider, "unload", provider_unload, 0);

    rb_mProbe = rb_define_class_under(rb_mUsdt, "Probe", rb_cObject);
    rb_define_method(rb_mProbe, "fire", probe_fire, -1);
    rb_define_method(rb_mProbe, "enabled?", probe_enabled_p, 0);
}

