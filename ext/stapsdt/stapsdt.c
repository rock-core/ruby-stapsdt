#include "stapsdt.h"

VALUE rb_mProvider;
VALUE rb_mProbe;
VALUE rb_mStapSDT;

typedef struct Provider
{
    SDTProvider_t* provider;
} Provider_t;

typedef struct Probe
{
    VALUE input_args[MAX_ARGUMENTS];
    SDTProbe_t* probe;
} Probe_t;

void provider_free(Provider_t* wrap)
{
    providerDestroy(wrap->provider);
    xfree(wrap);
}

VALUE provider_new(VALUE self, VALUE _name)
{
    char const* name = StringValueCStr(_name);
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
    VALUE input_args[MAX_ARGUMENTS];
    int args[MAX_ARGUMENTS];
    if (argc < 1)
        rb_raise(rb_eArgError, "expected at least 1 argument, got 0");
    if (argc > MAX_ARGUMENTS + 1)
        rb_raise(rb_eArgError,
            "libstapstd only supports up to %i arguments, got %i",
                MAX_ARGUMENTS, argc - 1);

    for (int i = 0; i < argc - 1; ++i)
    {
        VALUE arg_type = argv[i + 1];
        input_args[i] = arg_type;
        if (arg_type == rb_cString || arg_type == rb_cFloat || arg_type == rb_cInteger)
            args[i] = uint64;
        else
            args[i] = NUM2INT(arg_type);
    }

    char const* probe_name = StringValueCStr(argv[0]);

    Provider_t* wrap;
    Data_Get_Struct(self, Provider_t, wrap);

    SDTProbe_t* probe = NULL;
    if (argc == 1)
        probe = providerAddProbe(wrap->provider, probe_name, 0);
    else if (argc == 2)
        probe = providerAddProbe(wrap->provider, probe_name, 1,
            (ArgType_t)args[0]);
    else if (argc == 3)
        probe = providerAddProbe(wrap->provider, probe_name, 2,
            (ArgType_t)args[0], (ArgType_t)args[1]);
    else if (argc == 4)
        probe = providerAddProbe(wrap->provider, probe_name, 3,
            (ArgType_t)args[0], (ArgType_t)args[1], (ArgType_t)args[2]);
    else if (argc == 5)
        probe = providerAddProbe(wrap->provider, probe_name, 4,
            (ArgType_t)args[0], (ArgType_t)args[1], (ArgType_t)args[2],
            (ArgType_t)args[3]);
    else if (argc == 6)
        probe = providerAddProbe(wrap->provider, probe_name, 5,
            (ArgType_t)args[0], (ArgType_t)args[1], (ArgType_t)args[2],
            (ArgType_t)args[3], (ArgType_t)args[4]);
    else if (argc == 7)
        probe = providerAddProbe(wrap->provider, probe_name, 6,
            (ArgType_t)args[0], (ArgType_t)args[1], (ArgType_t)args[2],
            (ArgType_t)args[3], (ArgType_t)args[4], (ArgType_t)args[5]);

    if (!probe)
        rb_raise(rb_eArgError, "failed to create probe");

    Probe_t* probe_wrap = ALLOC(Probe_t);
    memcpy(probe_wrap->input_args, input_args, sizeof(VALUE)*(argc - 1));
    probe_wrap->probe = probe;
    /* NOTE: probes cannot be deallocated. They're freed when the provider is */
    return rb_data_object_wrap(rb_mProbe, probe_wrap, NULL, NULL);
}

VALUE probe_fire(int argc, VALUE* argv, VALUE self)
{

    uint64_t args[MAX_ARGUMENTS];
    VALUE block_args[MAX_ARGUMENTS];
    VALUE* in_args;

    Probe_t* wrap;
    Data_Get_Struct(self, Probe_t, wrap);
    int expected_argc = wrap->probe->argCount;

    if (rb_block_given_p()) {
        if (argc != 0)
        {
            rb_raise(rb_eArgError, "cannot provide arguments "\
                "and block at the same time");
        }

        if (!probeIsEnabled(wrap->probe)) {
            return Qfalse;
        }

        VALUE block_ret = rb_yield_values(0);
        if (!NIL_P(block_ret)) {
            argc = RARRAY_LEN(block_ret);
            if (argc != expected_argc)
                rb_raise(rb_eArgError, "expected %i argument(s), got %i",
                    expected_argc, argc);

            for (int i = 0; i < argc; ++i)
                block_args[i] = rb_ary_entry(block_ret, i);

            in_args = block_args;
        }
    }
    else {
        if (argc != expected_argc)
            rb_raise(rb_eArgError, "expected %i argument(s), got %i",
                expected_argc, argc);

        in_args = argv;
    }

    for (int i = 0; i < argc; ++i)
    {
        if (wrap->input_args[i] == rb_cString)
        {
            char const* s = StringValueCStr(in_args[i]);
            args[i] = *(uint64_t*)&s;
        }
        else if (wrap->input_args[i] == rb_cFloat)
        {
            double d = NUM2DBL(in_args[i]);
            args[i] = *(uint64_t*)&d;
        }
        else
            args[i] = NUM2ULL(in_args[i]);
    }

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

VALUE probe_name(VALUE self)
{
    Probe_t* wrap;
    Data_Get_Struct(self, Probe_t, wrap);
    return rb_str_new_cstr(wrap->probe->name);
}

void
Init_stapsdt(void)
{
    rb_mStapSDT = rb_define_module("StapSDT");
    rb_mProvider = rb_define_class_under(rb_mStapSDT, "Provider", rb_cObject);
    rb_define_singleton_method(rb_mProvider, "new", provider_new, 1);
    rb_define_method(rb_mProvider, "add_probe_c", provider_add_probe, -1);
    rb_define_method(rb_mProvider, "load_c", provider_load, 0);
    rb_define_method(rb_mProvider, "unload_c", provider_unload, 0);

    rb_mProbe = rb_define_class_under(rb_mStapSDT, "Probe", rb_cObject);
    rb_define_method(rb_mProbe, "fire", probe_fire, -1);
    rb_define_method(rb_mProbe, "enabled?", probe_enabled_p, 0);
    rb_define_method(rb_mProbe, "name", probe_name, 0);
}

