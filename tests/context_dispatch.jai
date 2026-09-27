#import "Basic";
Sliminal :: #import "Superliminal"(DLL = true);

#assert Sliminal.ENABLED && Sliminal.DLL;

main :: () {
    assert(!Sliminal.init(null));
    assert(Sliminal.init(test_get_api));
    Sliminal.set_thread_name("Dispatch test");
    Sliminal.register_fiber(10);
    Sliminal.begin_fiber_switch(10, 20);
    Sliminal.end_fiber_switch(10);
    Sliminal.unregister_fiber(10);
    assert(fiber_calls == 15);

    Sliminal.begin("Explicit", "Data", Sliminal.COLOR_RED);
    Sliminal.end();
    assert(last_color == Sliminal.COLOR_RED);
    exercise_scope();
    assert(begin_calls == 2 && end_calls == 2);

    saved_begin := context.superliminal_api.BeginEventN;
    assert(!Sliminal.init(reject_get_api));
    assert(context.superliminal_api.BeginEventN == saved_begin);
    nested_context := context;
    nested_context.superliminal_api.BeginEventN = alternate_begin;
    push_context nested_context {
        exercise_scope();
    }
    assert(alternate_calls == 1 && begin_calls == 2 && end_calls == 3);
    exercise_scope();
    assert(begin_calls == 3 && end_calls == 4);

    print("PASS: context tests.\n");
}

exercise_scope :: () {
    Sliminal.scope("Scope", color = Sliminal.COLOR_PURPLE);
    return;
}

begin_calls: int;
end_calls: int;
alternate_calls: int;
last_color: u32;
fiber_calls: u32;

// These are bogus functions that match the API signature of Superliminal so that we pretend we're in DLL mode without loading the library.
test_get_api :: (version: s32, api: *Sliminal.PerformanceAPI_Functions) -> s32 #c_call {
    if version != Sliminal.VERSION return 0;
    api.BeginEventN = test_begin;
    api.EndEvent = test_end;
    api.SetCurrentThreadNameN = test_thread_name;
    api.RegisterFiber = test_register_fiber;
    api.UnregisterFiber = test_unregister_fiber;
    api.BeginFiberSwitch = test_begin_fiber_switch;
    api.EndFiberSwitch = test_end_fiber_switch;
    return 1;
}

reject_get_api :: (version: s32, api: *Sliminal.PerformanceAPI_Functions) -> s32 #c_call {
    api.BeginEventN = alternate_begin;
    return 0;
}

test_begin :: (name: *u8, name_length: u16, data: *u8, data_length: u16, color: u32) #c_call {
    begin_calls += 1;
    last_color = color;
}

alternate_begin :: (name: *u8, name_length: u16, data: *u8, data_length: u16, color: u32) #c_call {
    alternate_calls += 1;
}

test_end :: () -> Sliminal.SuppressTailCallOptimization #c_call {
    end_calls += 1;
    return .{};
}

test_thread_name :: (name: *u8, length: u16) #c_call {
    push_context {
        assert(length == 13);
    }
}

test_register_fiber :: (id: u64) #c_call {
    if id == 10 fiber_calls |= 1;
}

test_unregister_fiber :: (id: u64) #c_call {
    if id == 10 fiber_calls |= 2;
}

test_begin_fiber_switch :: (current_id: u64, new_id: u64) #c_call {
    if current_id == 10 && new_id == 20 fiber_calls |= 4;
}

test_end_fiber_switch :: (id: u64) #c_call {
    if id == 10 fiber_calls |= 8;
}