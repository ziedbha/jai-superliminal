#import "Basic";
#import "Bindings_Generator";
#import "Compiler";
#import "File";
#import "File_Utilities";
#import "String";
#import "Process";

AT_COMPILE_TIME     :: true; // Set false to build generate.exe
RUN_TESTS           :: true;  // Build and run tests after generating the package
OUTPUT_DIRECTORY    :: "generated/Superluminal";
SOURCE_PATH         :: "superluminal";
LIB_BASE_NAME       :: "PerformanceAPI";
LIB_IDENTIFIER      :: "performance_api";

#if RUN_TESTS {
    #if OS == .WINDOWS {
        JAI_COMPILER :: #run sprint("%/bin/jai.exe", compiler_get_base_path());
    } else {
        JAI_COMPILER :: #run sprint("%/bin/jai", compiler_get_base_path());
    }
}

#if AT_COMPILE_TIME {
    #run,stallable {
        set_build_options_dc(.{do_output = false});
        set_working_directory(#filepath);
        if !generate_bindings() compiler_set_workspace_status(.FAILED);
    }
} else {
    #import "System";

    // The standalone generator needs libclang beside the executable before main can run.
    #run {
        set_working_directory(#filepath);
        ensure_local_libclang_exists();
    }

    main :: () {
        set_working_directory(path_strip_filename(get_path_of_running_executable()));
        if !generate_bindings() {
            log_error("Failed to generate bindings");
            exit(1);
        }
    }
}

generate_bindings :: () -> bool {
    print("Generating Superluminal bindings for %/%...\n", OS, CPU);
    platform_directory: string;
    lib_directory: string;
    sdk_lib_name: string;
    library_suffix: string;
    source_file: string;
    extra_clang_arguments: [] string;
    dll_file: string;

    #if OS == {
        case .WINDOWS;
            #assert CPU == .X64;
            platform_directory      = "windows";
            lib_directory           = tprint("%/lib/x64", SOURCE_PATH);
            sdk_lib_name            = "PerformanceAPI_MT";
            library_suffix          = ".lib";
            dll_file                = tprint("%/dll/x64/PerformanceAPI.dll", SOURCE_PATH);
            source_file             = tprint("%/include/Superluminal/PerformanceAPI_capi.h", SOURCE_PATH);
            extra_clang_arguments   = .["-x", "c++", "-DPERFORMANCEAPI_ENABLED=1"];
        case .LINUX;
            log_error("Linux generation requires a Linux instrumentation SDK; none is configured yet.");
            return false;
        case .MACOS;
            log_error("macOS generation requires a macOS instrumentation SDK; none is configured yet.");
            return false;
        case;
            log_error("Unsupported target OS: %", OS);
            return false;
    }

    library_file := tprint("%/%%", lib_directory, sdk_lib_name, library_suffix);
    if !file_exists(source_file) || !file_exists(library_file) || !file_exists(dll_file) {
        log_error("Copy the contents of Superluminal's API folder into %/ before generating. Expected %, %, and %.", SOURCE_PATH, source_file, library_file, dll_file);
        return false;
    }
    if !make_directory_if_it_does_not_exist(tprint("%/%", OUTPUT_DIRECTORY, platform_directory), recursive = true) {
        log_error("Could not create the output package directory.");
        return false;
    }

    options: Generate_Bindings_Options;
    options.generate_library_declarations = false;
    options.generate_compile_time_struct_checks = false; // true for more verbose checks
    options.try_to_preserve_comments = true; // The visitor replaces SDK documentation with short section comments.
    options.mimic_spacing_flags = 0;
    options.visitor_with_data = visit_superluminal_api;

    array_add(*options.library_search_paths, lib_directory);
    array_add(*options.libraries, .{filename = sdk_lib_name, identifier = LIB_IDENTIFIER});
    array_add(*options.source_files, source_file);
    array_add(*options.extra_clang_arguments, ..extra_clang_arguments);
    array_add(*options.strip_prefixes, "PerformanceAPI_", "PERFORMANCEAPI_");

    print("Reading SDK header: %\n", source_file);
    bindings, generated := generate_bindings(options, log_results = true);
    if !generated return false;

    // Keep the native declarations in the same file, but exclude them from DLL builds.
    output: String_Builder;
    in_direct_bindings := false;
    for split(builder_to_string(*bindings), "\n") {
        is_direct := find_index_from_left(it, "#foreign") != -1;
        if is_direct && !in_direct_bindings append(*output, "#if !DLL {\n");
        if !is_direct && in_direct_bindings append(*output, "}\n");
        if is_direct append(*output, "    ");
        print_to_builder(*output, "%\n", it);
        in_direct_bindings = is_direct;
    }

    output_file := tprint("%/%/%.jai", OUTPUT_DIRECTORY, platform_directory, platform_directory);
    if !write_entire_file(output_file, *output) {
        log_error("Could not write generated bindings: %", output_file);
        return false;
    }
    print("Wrote bindings: %\n", output_file);

    print("Copying SDK library, DLL, and module files to %/...\n", OUTPUT_DIRECTORY);
    success := copy_file(library_file, tprint("%/%/%%", OUTPUT_DIRECTORY, platform_directory, LIB_BASE_NAME, library_suffix));
    success &&= copy_file(dll_file, tprint("%/%/%.dll", OUTPUT_DIRECTORY, platform_directory, LIB_BASE_NAME));
    success &&= copy_file("module/module.jai", tprint("%/module.jai", OUTPUT_DIRECTORY));
    success &&= copy_file("module/runtime.jai", tprint("%/runtime.jai", OUTPUT_DIRECTORY));
    if !success {
        log_error("Could not copy all files into the output package.");
        return false;
    }
    print("Package ready: %/\n", OUTPUT_DIRECTORY);

    #if RUN_TESTS {
        print("Building and running tests...\n");
        result := run_command(JAI_COMPILER, "tests/build.jai", capture_and_return_output = true, print_captured_output = true);
        if result.type != .EXITED || result.exit_code != 0 {
            log_error("Test build or execution failed (%, exit code %).", result.type, result.exit_code);
            return false;
        }
    }
    return true;
}

visit_superluminal_api :: (decl: *Declaration, parent: *Declaration, user_data: *void) -> Declaration_Visit_Result {
    if !parent && (decl.name == "PERFORMANCEAPI_ENABLED" || (!begins_with(decl.name, "PerformanceAPI_") && !begins_with(decl.name, "PERFORMANCEAPI_"))) {
        decl.decl_flags |= .OMIT_FROM_OUTPUT;
        return .STOP;
    }
    decl.comment.text = "";

    if !parent {
        if decl.name == {
            case "PERFORMANCEAPI_MAJOR_VERSION";
                decl.comment.text = "// SDK version and default event color.";
            case "PerformanceAPI_SuppressTailCallOptimization";
                decl.comment.text = "// EndEvent returns this ABI structure to prevent tail calls; callers ignore its value.";
            case "PerformanceAPI_SetCurrentThreadName";
                decl.comment.text = "// Direct bindings of the static SDK library.";
            case "PerformanceAPI_SetCurrentThreadName_Func";
                decl.comment.text = "// Function-pointer types. Counterpart to lib symbols so that you may use the library dynamically as well.";
            case "PerformanceAPI_Functions";
                decl.comment.text = "// Dispatch table populated by GetAPI. Use this if you are loading the library dynamically.";
                decl.output_name = decl.name;
            case "PerformanceAPI_GetAPI_Func";
                decl.comment.text = "// Type of the vendor DLL's exported PerformanceAPI_GetAPI entry point. Pass VERSION.";
        }
        if decl.comment.text {
            decl.comment.location = decl.location;
            if decl.name != "PERFORMANCEAPI_MAJOR_VERSION" decl.comment.text = tprint("\n%", decl.comment.text);
        }
    }
    if parent && parent.kind == .FUNCTION && begins_with(parent.name, "PerformanceAPI_BeginEvent") && decl.name == "inColor" decl.expression = create_literal("DEFAULT_COLOR", decl.location);
    return .RECURSE;
}
