#import "Basic";
Sliminal :: #import "Superliminal"(DLL = TEST_DLL);

#assert Sliminal.ENABLED;

#if TEST_DLL {
    W :: #import "Windows";
    DLL_PATH :: #run sprint("%/../generated/Superliminal/windows/PerformanceAPI.dll", #filepath);
}

main :: () {
    // Only setup depends on the backend. The event tests below use the same public API.
    #if TEST_DLL {
        dll := W.LoadLibraryA(DLL_PATH);
        assert(dll != null, "Could not load the generated PerformanceAPI.dll");
        get_api := cast(Sliminal.GetAPI_Func) W.GetProcAddress(dll, "PerformanceAPI_GetAPI");
        assert(Sliminal.init(get_api));
    }
    defer {
        #if TEST_DLL {
            context.superliminal_api = .{};
            W.FreeLibrary(dll);
        }
    }

    Sliminal.set_thread_name("Event tests");
    for iteration: 0..15 {
        Sliminal.begin("Iteration");
        defer Sliminal.end();
        test_scoped_events(iteration);
        test_explicit_events(iteration);
    }
    print("PASS: regular usage tests.\n");
}

test_scoped_events :: (iteration: int) {
    Sliminal.scope("Scoped event", tprint("iteration %", iteration), Sliminal.COLOR_BLUE);
    if iteration % 2 == 0 return;
    {
        Sliminal.scope("Nested scoped event", color = Sliminal.COLOR_PURPLE);
    }
}

test_explicit_events :: (iteration: int) {
    Sliminal.begin("Explicit event", tprint("iteration %", iteration), Sliminal.COLOR_GREEN);
    defer Sliminal.end();
    if iteration % 2 == 1 return;
    {
        Sliminal.begin("Nested explicit event", color = Sliminal.COLOR_YELLOW);
        defer Sliminal.end();
    }
}