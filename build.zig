const std = @import("std");
const build_zig_zon = @import("build.zig.zon");
const toolbox = @import("toolbox");
const VerboseBuilder = toolbox.VerboseBuilder;

fn updateFn(pkg_builder: *VerboseBuilder) !void {
    try pkg_builder.remove(&.{"vulkan"});
    try pkg_builder.make(&.{"vulkan"});

    const vulkan_headers_dep = pkg_builder.dependency("Vulkan-Headers");
    var vulkan_headers_builder = VerboseBuilder.initFromDependency(vulkan_headers_dep);

    while (try vulkan_headers_builder.walk(&.{"include"})) |entry| {
        switch (entry.kind) {
            .file => {
                if (toolbox.isCOrCppFile(entry.basename)) {
                    try pkg_builder.copy(&.{ "vulkan", entry.path }, &vulkan_headers_builder, &.{ "include", entry.path });
                }
            },
            .directory => try pkg_builder.make(&.{ "vulkan", entry.path }),
            else => return error.UnexpectedEntryKind,
        }
    }
}

fn buildFn(pkg_builder: *VerboseBuilder) !void {
    const lib = pkg_builder.addLibrary("vulkan");

    pkg_builder.installHeaders(lib, &.{ "vulkan", "vulkan" }, "vulkan", &toolbox.ext.cpp.header.c_compatible);
    pkg_builder.installHeaders(lib, &.{ "vulkan", "vk_video" }, "vk_video", &toolbox.ext.cpp.header.c_compatible);

    pkg_builder.installArtifact(lib);
}

pub fn build(builder: *std.Build) !void {
    var pkg_builder = try VerboseBuilder.init(builder, build_zig_zon, buildFn, updateFn);

    try pkg_builder.fetch(build_zig_zon);
    try pkg_builder.update();
    try pkg_builder.build();
}
