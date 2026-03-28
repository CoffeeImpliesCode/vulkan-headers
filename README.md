# vulkan.zig

This is a fork of [hexops/vulkan-headers][1] which is itself a fork of [KhronosGroup/Vulkan-Headers][2].

## Why this forkception ?

The intention under this fork is the same as [hexops][4] had when they forked [KhronosGroup/Vulkan-Headers][2]: package the headers for [Zig][3]. So:
* Unnecessary files have been deleted,
* The build system has been replaced with `build.zig`.

However this repository has subtle differences for maintainability tasks:
* No shell scripting,
* A cron runs every day to check [KhronosGroup/Vulkan-Headers][2] and other dependencies. Then it updates this repository if a new release is available.

## Dependencies

The [Zig][3] part of this package is relying on the latest [Zig][3] release (0.15.2) and will only be updated for the next one.
It you use a more recent [Zig][3] version, please consider the `zig-nightly` branch and `*-nightly` tags.

For other dependencies see [the build.zig.zon](https://github.com/tiawl/vulkan.zig/blob/zig-stable/build.zig.zon)

## `zig build` options

These additional options have mainly been implemented for maintainability tasks but they maybe could be useful for edge usecases:
```
  -Dfetch   Update build.zig.zon then stop execution
  -Dupdate  Update binding
```

## License

This repository is not subject to a unique License:

The parts of this repository originated from this repository are dedicated to the public domain. See the LICENSE file for more details.

**For other parts, it is subject to the License restrictions their respective owners choosed. By design, the public domain code is incompatible with the License notion. In this case, the License prevails. So if you have any doubt about a file property, open an issue.**

[1]:https://github.com/hexops/vulkan-headers
[2]:https://github.com/KhronosGroup/Vulkan-Headers
[3]:https://codeberg.org/ziglang/zig
[4]:https://github.com/hexops
