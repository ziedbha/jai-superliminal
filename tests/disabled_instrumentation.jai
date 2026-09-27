#import "Basic";
Sliminal :: #import "Superliminal"(ENABLED = false);

#assert !Sliminal.ENABLED;

main :: () {
    calls: s64;
    Sliminal.begin("Disabled begin", evaluate_data(*calls));
    defer Sliminal.end();
    Sliminal.scope("Disabled scope", evaluate_data(*calls), Sliminal.COLOR_PURPLE);
    Sliminal.set_thread_name(evaluate_data(*calls));
    assert(calls == 0, "Disabled instrumentation evaluated its data arguments");
    print("PASS: disabled instrumentation tests.\n");
}

evaluate_data :: (calls: *s64) -> string {
    calls.* += 1;
    return "Should not be evaluated";
}