#module_parameters (ENABLED := OS == .WINDOWS && CPU == .X64, DLL := false);

SUPPORTED :: OS == .WINDOWS && CPU == .X64;

#if ENABLED {
    #assert SUPPORTED;
    #if OS == .WINDOWS {
        #load "windows/windows.jai";
    } else #if OS == .LINUX {
        #load "linux/linux.jai";
    } else #if OS == .MACOS {
        #load "macos/macos.jai";
    } else {
        #assert false;
    }
}

#load "runtime.jai";

#scope_module

#if ENABLED && !DLL {
    #if OS == .WINDOWS {
        performance_api :: #library,no_dll "windows/PerformanceAPI";
        #library,system,link_always "libcpmt";
    } else #if OS == .LINUX {
        performance_api :: #library,no_dll "linux/PerformanceAPI";
    } else #if OS == .MACOS {
        performance_api :: #library,no_dll "macos/PerformanceAPI";
    } else {
        #assert false;
    }
}
