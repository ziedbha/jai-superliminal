#import "Basic";
#import "Compiler";
#import "File";
#import "Process";

#run,stallable {
    options := get_build_options();
    set_build_options_dc(.{do_output = false});
    options.output_path = tprint("%/.build", #filepath);
    options.intermediate_path = options.output_path;
    if !make_directory_if_it_does_not_exist(options.output_path, recursive = true) {
        compiler_report("Could not create tests/.build.");
        return;
    }
    executables: [..] string;

    module_paths: [..] string;
    array_add(*module_paths, ..options.import_path);
    array_add(*module_paths, tprint("%/../generated", #filepath));
    options.import_path = module_paths;

    {
        workspace := compiler_create_workspace();
        options.output_executable_name = "events_static";
        set_optimization(*options, .DEBUG);
        set_build_options(options, workspace);
        array_add(*executables, tprint("%/%.exe", options.output_path, options.output_executable_name));
        compiler_begin_intercept(workspace);
        add_build_string("TEST_DLL :: false;", workspace);
        add_build_file(tprint("%/events.jai", #filepath), workspace);
    }

    {
        workspace := compiler_create_workspace();
        options.output_executable_name = "events_static_optimized";
        set_optimization(*options, .VERY_OPTIMIZED);
        set_build_options(options, workspace);
        array_add(*executables, tprint("%/%.exe", options.output_path, options.output_executable_name));
        compiler_begin_intercept(workspace);
        add_build_string("TEST_DLL :: false;", workspace);
        add_build_file(tprint("%/events.jai", #filepath), workspace);
    }

    {
        workspace := compiler_create_workspace();
        options.output_executable_name = "events_dll";
        set_optimization(*options, .DEBUG);
        set_build_options(options, workspace);
        array_add(*executables, tprint("%/%.exe", options.output_path, options.output_executable_name));
        compiler_begin_intercept(workspace);
        add_build_string("TEST_DLL :: true;", workspace);
        add_build_file(tprint("%/events.jai", #filepath), workspace);
    }

    {
        workspace := compiler_create_workspace();
        options.output_executable_name = "events_dll_optimized";
        set_optimization(*options, .VERY_OPTIMIZED);
        set_build_options(options, workspace);
        array_add(*executables, tprint("%/%.exe", options.output_path, options.output_executable_name));
        compiler_begin_intercept(workspace);
        add_build_string("TEST_DLL :: true;", workspace);
        add_build_file(tprint("%/events.jai", #filepath), workspace);
    }

    {
        workspace := compiler_create_workspace();
        options.output_executable_name = "context_dispatch";
        set_optimization(*options, .DEBUG);
        set_build_options(options, workspace);
        array_add(*executables, tprint("%/%.exe", options.output_path, options.output_executable_name));
        compiler_begin_intercept(workspace);
        add_build_file(tprint("%/context_dispatch.jai", #filepath), workspace);
    }

    {
        workspace := compiler_create_workspace();
        options.output_executable_name = "context_dispatch_optimized";
        set_optimization(*options, .VERY_OPTIMIZED);
        set_build_options(options, workspace);
        array_add(*executables, tprint("%/%.exe", options.output_path, options.output_executable_name));
        compiler_begin_intercept(workspace);
        add_build_file(tprint("%/context_dispatch.jai", #filepath), workspace);
    }

    {
        workspace := compiler_create_workspace();
        options.output_executable_name = "disabled_instrumentation";
        set_optimization(*options, .DEBUG);
        set_build_options(options, workspace);
        array_add(*executables, tprint("%/%.exe", options.output_path, options.output_executable_name));
        compiler_begin_intercept(workspace);
        add_build_file(tprint("%/disabled_instrumentation.jai", #filepath), workspace);
    }

    remaining := executables.count;
    compilation_failed := false;
    while remaining > 0 {
        message := compiler_wait_for_message();
        if message.kind != .COMPLETE continue;
        complete := cast(*Message_Complete) message;
        if complete.error_code != .NONE compilation_failed = true;
        compiler_end_intercept(message.workspace);
        remaining -= 1;
    }
    if compilation_failed {
        compiler_set_workspace_status(.FAILED);
        return;
    }

    print("\nAll tests compiled. Running % tests...\n", executables.count);
    for executables {
        print("Running %\n", it);
        result := run_command(it, capture_and_return_output = true, print_captured_output = true);
        if result.type != .EXITED || result.exit_code != 0 {
            compiler_report(tprint("Test failed: % (exit code %).", it, result.exit_code));
            return;
        }
    }
    print("All % tests passed.\n", executables.count);
}