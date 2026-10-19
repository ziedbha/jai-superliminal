// Named event colors in the SDK's 0xRRGGBBFF format
COLOR_RED    :: 0xff0000ff;
COLOR_GREEN  :: 0x00ff00ff;
COLOR_BLUE   :: 0x0000ffff;
COLOR_YELLOW :: 0xffff00ff;
COLOR_PURPLE :: 0x800080ff;

#if ENABLED {
    #if DLL {
        #add_context superluminal_api: PerformanceAPI_Functions;

        // Make sure to call this once after loading in the library yourself for every thread that needs profiling.
        // It will setup the context's `superluminal_api` to point to the API table so that you may just call
        // `begin` and `end` without passing around the table yourself.
        init :: (get_api: GetAPI_Func) -> bool {
            if !get_api return false;
            api: PerformanceAPI_Functions;
            if get_api(VERSION, *api) == 0 return false;
            context.superluminal_api = api;
            return true;
        }
    }

    begin :: inline (name: string, data: string = "", color: u32 = DEFAULT_COLOR) {
        assert(name.count <= 0xffff && data.count <= 0xffff, "Performance API strings must fit in u16");
        #if DLL {
            assert(context.superluminal_api.BeginEventN != null, "Initialize the Superluminal API in this context before profiling");
            context.superluminal_api.BeginEventN(name.data, cast(u16) name.count, data.data, cast(u16) data.count, color);
        } else {
            BeginEvent_N(name.data, cast(u16) name.count, data.data, cast(u16) data.count, color);
        }
    }

    end :: inline () {
        #if DLL {
            context.superluminal_api.EndEvent();
        } else {
            EndEvent();
        }
    }

    scope :: ($name: string, data: string = "", color: u32 = DEFAULT_COLOR) #expand #no_debug {
        begin(name, data, color);
        `defer end();
    }

    set_thread_name :: inline (name: string) {
        assert(name.count <= 0xffff, "Performance API thread names must fit in u16");
        #if DLL {
            context.superluminal_api.SetCurrentThreadNameN(name.data, cast(u16) name.count);
        } else {
            SetCurrentThreadName_N(name.data, cast(u16) name.count);
        }
    }

    register_fiber :: inline (id: u64) {
        #if DLL {
            context.superluminal_api.RegisterFiber(id);
        } else {
            RegisterFiber(id);
        }
    }

    unregister_fiber :: inline (id: u64) {
        #if DLL {
            context.superluminal_api.UnregisterFiber(id);
        } else {
            UnregisterFiber(id);
        }
    }

    begin_fiber_switch :: inline (current_id: u64, new_id: u64) {
        #if DLL {
            context.superluminal_api.BeginFiberSwitch(current_id, new_id);
        } else {
            BeginFiberSwitch(current_id, new_id);
        }
    }

    end_fiber_switch :: inline (id: u64) {
        #if DLL {
            context.superluminal_api.EndFiberSwitch(id);
        } else {
            EndFiberSwitch(id);
        }
    }
} else {
    DEFAULT_COLOR :: 0xffffffff;

    begin :: (#discard name: string, #discard data: string = "", #discard color: u32 = DEFAULT_COLOR) #expand #no_debug {}
    end :: () #expand #no_debug {}
    scope :: ($name: string, #discard data: string = "", #discard color: u32 = DEFAULT_COLOR) #expand #no_debug {}
    set_thread_name :: (#discard name: string) #expand #no_debug {}
    register_fiber :: (#discard id: u64) #expand #no_debug {}
    unregister_fiber :: (#discard id: u64) #expand #no_debug {}
    begin_fiber_switch :: (#discard current_id: u64, #discard new_id: u64) #expand #no_debug {}
    end_fiber_switch :: (#discard id: u64) #expand #no_debug {}
}

#scope_file
#import "Basic"; // assert()