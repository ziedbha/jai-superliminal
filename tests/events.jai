#import "Basic";
Sluminal :: #import "Superluminal"(DLL = TEST_DLL);

#assert Sluminal.ENABLED;

#if TEST_DLL {
    W :: #import "Windows";
    DLL_PATH :: #run sprint("%/../generated/Superluminal/windows/PerformanceAPI.dll", #filepath);
}

main :: () {
    // Only setup depends on the backend. The event tests below use the same public API.
    #if TEST_DLL {
        dll := W.LoadLibraryA(DLL_PATH);
        assert(dll != null, "Could not load the generated PerformanceAPI.dll");
        get_api := cast(Sluminal.GetAPI_Func) W.GetProcAddress(dll, "PerformanceAPI_GetAPI");
        assert(Sluminal.init(get_api));
    }
    defer {
        #if TEST_DLL {
            context.superluminal_api = .{};
            W.FreeLibrary(dll);
        }
    }

    Sluminal.set_thread_name("Event tests");
    for iteration: 0..15 {
        Sluminal.begin("Iteration");
        defer Sluminal.end();
        test_scoped_events(iteration);
        test_explicit_events(iteration);
    }
    print("PASS: regular usage tests.\n");
}

test_scoped_events :: (iteration: int) {
    Sluminal.scope("Scoped event", tprint("iteration %", iteration), Sluminal.COLOR_BLUE);
    if iteration % 2 == 0 return;
    {
        Sluminal.scope("Nested scoped event", color = Sluminal.COLOR_PURPLE);
    }
}

test_explicit_events :: (iteration: int) {
    Sluminal.begin("Explicit event", tprint("iteration %", iteration), Sluminal.COLOR_GREEN);
    defer Sluminal.end();
    if iteration % 2 == 1 return;
    {
        Sluminal.begin("Nested explicit event", color = Sluminal.COLOR_YELLOW);
        defer Sluminal.end();
    }
}