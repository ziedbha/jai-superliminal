#import "Basic";
Sluminal :: #import "Superluminal"(ENABLED = false);

#assert !Sluminal.ENABLED;

main :: () {
    calls: s64;
    Sluminal.begin("Disabled begin", evaluate_data(*calls));
    defer Sluminal.end();
    Sluminal.scope("Disabled scope", evaluate_data(*calls), Sluminal.COLOR_PURPLE);
    Sluminal.set_thread_name(evaluate_data(*calls));
    assert(calls == 0, "Disabled instrumentation evaluated its data arguments");
    print("PASS: disabled instrumentation tests.\n");
}

evaluate_data :: (calls: *s64) -> string {
    calls.* += 1;
    return "Should not be evaluated";
}