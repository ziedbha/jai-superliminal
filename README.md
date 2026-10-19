# Superluminal profiler bindings for Jai

## Disclaimer: this work is not affiliated with Superluminal

Jai bindings for the [Superluminal profiler](https://superluminal.eu/), currently only supporting Windows x64.

## Setup

1. Copy the contents of your Superluminal installation's `API` folder into `superluminal/`. E.g. on Windows this is typically somewhere here `C:\Program Files\Superluminal\Performance\API`
2. Run `jai generate.jai` from the repository root.

### Notes on building the bindings

* The SDK and generated package are intentionally not included in this repository.
* Set `RUN_TESTS` to `false` to skip tests, or run them separately with `jai tests/build.jai`. Test outputs stay in `tests/.build`.
* Set `AT_COMPILE_TIME` to `false` to build an executable that you can reuse for bindings generation.

## Profiling run-time code

```jai
Sluminal :: #import "Superluminal";

update :: () {
    Sluminal.scope("Update", color = Sluminal.COLOR_BLUE);
}
```

### Notes on dynamic/static linking

The bindings allow for unified usage regardless if you're statically or dynamically linking the SDK libs. This is done using the #context utilities in Jai.

For DLL mode, import with `DLL = true`, load the SDK dll, then pass the `GetAPI` func pointer to to `init`. This will modify your context such that calling the runtime funcs `begin` and `end` will reference the dispatch table given by `GetAPI`. 

## More information

See the [Superluminal documentation](https://superluminal.eu/docs/documentation.html).
