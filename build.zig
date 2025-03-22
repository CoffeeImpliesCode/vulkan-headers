const std = @import("std");
const toolbox = @import("toolbox");

fn update(vulkan_path: []const u8, dependencies: *const toolbox.Dependencies) !void {
    const tmp_path = try toolbox.instance().getBuilder().build_root.join(toolbox.instance().getBuilder().allocator, &.{
        "tmp",
    });
    const include_path = toolbox.instance().ptrBuilder().pathJoin(&.{
        tmp_path, "include",
    });

    std.fs.deleteTreeAbsolute(vulkan_path) catch |err| {
        switch (err) {
            error.FileNotFound => {},
            else => return err,
        }
    };

    try dependencies.clone("vulkan", tmp_path);

    var include_dir = try std.fs.openDirAbsolute(include_path, .{
        .iterate = true,
    });
    defer include_dir.close();

    var walker = try include_dir.walk(toolbox.instance().getBuilder().allocator);
    defer walker.deinit();

    try toolbox.instance().make(vulkan_path);

    while (try walker.next()) |*entry| {
        const dest = toolbox.instance().ptrBuilder().pathJoin(&.{
            vulkan_path, entry.path,
        });
        switch (entry.kind) {
            .file => try toolbox.instance().copy(toolbox.instance().ptrBuilder().pathJoin(&.{
                include_path, entry.path,
            }), dest),
            .directory => try toolbox.instance().make(dest),
            else => return error.UnexpectedEntryKind,
        }
    }

    try std.fs.deleteTreeAbsolute(tmp_path);

    try toolbox.instance().clean(&.{
        "vulkan",
    }, &.{});
}

pub fn build(builder: *std.Build) !void {
    const target = builder.standardTargetOptions(.{});
    const optimize = builder.standardOptimizeOption(.{});

    toolbox.init(builder, optimize);
    defer toolbox.deinit();
    const dependencies = try toolbox.Dependencies.init(.vulkan_zig, "0xe457756cde206ca7", &.{
        "vulkan",
    }, .{
        .toolbox = .{
            .name = "tiawl/toolbox",
            .host = toolbox.Repository.Host.github,
            .ref = toolbox.Repository.Reference.tag,
        },
    }, .{
        .vulkan = .{
            .name = "KhronosGroup/Vulkan-Headers",
            .host = toolbox.Repository.Host.github,
            .ref = toolbox.Repository.Reference.tag,
        },
    });

    const vulkan_path = try toolbox.instance().getBuilder().build_root.join(toolbox.instance().getBuilder().allocator, &.{
        "vulkan",
    });

    if (toolbox.instance().getUpdate()) {
        try update(vulkan_path, &dependencies);
    }

    const lib = toolbox.instance().ptrBuilder().addStaticLibrary(.{
        .name = "vulkan",
        .root_source_file = toolbox.instance().ptrBuilder().addWriteFiles().add("empty.c", ""),
        .target = target,
        .optimize = optimize,
    });

    var vulkan_dir = try std.fs.openDirAbsolute(vulkan_path, .{
        .iterate = true,
    });
    defer vulkan_dir.close();

    var it = vulkan_dir.iterate();
    while (try it.next()) |*entry| {
        if (entry.kind == .directory) {
            toolbox.instance().addHeader(lib, toolbox.instance().ptrBuilder().pathJoin(&.{
                vulkan_path, entry.name,
            }), entry.name, &.{
                ".h", ".hpp",
            });
        }
    }

    toolbox.instance().ptrBuilder().installArtifact(lib);
}
