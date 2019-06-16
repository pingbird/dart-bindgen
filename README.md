# dart-bindgen - A WIP package for generating dart:ffi C library bindings using libclang

### Design goals
* Automatically extract all declarations from a C library's header files.
* Provide an easy to use CLI to organize and map C functions to their binding Dart classes.
* Automatically resolve name conflicts, overloaded functions, etc.
* Make it easy for maintainers to provide their own filters and code generators.
* Produce packages which do not require users to compile their own libraries or native extensions.
* Self-hosting, C/C++ parsing should be done through FFI to give more control to maintainers (This requires bootstrapping by using C++ to generate the initial bindings, see below).
* Allow binding packages to depend on other binding packages, and automatically prevent conflicts between them.

### MVP implementation progress
- [x] Generate libclang binding information using libclang in C++ [PixelToast/bindgen-bootstrap](https://github.com/PixelToast/bindgen-bootstrap), also serves as a test for the initial binding generation.
- [x] Parse binding generation in dart-bindgen into something usable.
- [ ] Finish basic filtering, renaming, and binding code generation.
- [ ] Create and test a libclang binding using bindgen.
- [ ] Rewrite bindgen-bootstrap in Dart using the libclang bindings, making bindgen entirely self-hosting.
- [ ] Profit.

### Waiting on better ffi support
dart:ffi is unsable and extremely limited, in it's current state it is not possible to write a basic abi-agnostic binding to a C library:
* The supported integer types are explicitly sized, i.e. we have `uint32_t` but not `int`, most libraries do not use the sized integer types. [#36140](https://github.com/dart-lang/sdk/issues/36140)
* Nested structs are not supported. [37271](https://github.com/dart-lang/sdk/issues/37271)
* Returning structs by value is not supported. [37229](https://github.com/dart-lang/sdk/issues/37229)
* Structs do not support alignas, offsetof, etc.

Despite these limitations I think it should be possible to get libclang binding working, at least enough for bindgen-bootstrap on Linux

### In the future
Many C APIs use `#define` with a cast for constant values but bindgen isn't designed to parse them at the moment, it is possible to extract typed constants in the same way I do with const variable declarations.

Because this is based on libclang it is possible to generate bindings for more complex C++ libraries but it will be difficult to work with templated code, automatic binding generation can only go so far which is why I am spending extra time to make the tooling easier to extend.

In order to support inline functions or you most likely have to compile an extra shared library which expose those, it would be nice to provide a utility to extract inline functions and compile them automatically.
