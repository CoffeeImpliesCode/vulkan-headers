const std = @import("std");
const toolbox_pkg = @import("toolbox");
const Toolbox = toolbox_pkg.Toolbox;

fn update(toolbox: *Toolbox, vulkan_path: []const u8) !void {
    const tmp_path = try toolbox.buildRootJoin(&.{
        "tmp",
    });
    const include_path = toolbox.pathJoin(&.{
        tmp_path, "include",
    });

    std.fs.deleteTreeAbsolute(vulkan_path) catch |err| {
        switch (err) {
            error.FileNotFound => {},
            else => return err,
        }
    };

    try toolbox.clone(.vulkan, tmp_path);

    var include_dir = try std.fs.openDirAbsolute(include_path, .{
        .iterate = true,
    });
    defer include_dir.close();

    var walker = try include_dir.walk(toolbox.getAllocator());
    defer walker.deinit();

    try toolbox.make(vulkan_path);

    while (try walker.next()) |*entry| {
        const dest = toolbox.pathJoin(&.{
            vulkan_path, entry.path,
        });
        switch (entry.kind) {
            .file => try toolbox.copy(toolbox.pathJoin(&.{
                include_path, entry.path,
            }), dest),
            .directory => try toolbox.make(dest),
            else => return error.UnexpectedEntryKind,
        }
    }

    try std.fs.deleteTreeAbsolute(tmp_path);

    try toolbox.clean(&.{
        "vulkan",
    }, &.{});
}

const FromZon = toolbox_pkg.Repositories(.{
    .toolbox,
});

const DuringExec = toolbox_pkg.Repositories(.{
    .vulkan,
});

pub fn build(builder: *std.Build) !void {
    const target = builder.standardTargetOptions(.{});
    const optimize = builder.standardOptimizeOption(.{});

    var toolbox = try Toolbox.init(FromZon, DuringExec, builder, optimize, .vulkan_zig, "0xe457756cde206ca7", &.{
        "vulkan",
    }, .{
        .toolbox = .{
            .name = "tiawl/toolbox",
            .host = .github,
            .ref = .tag,
        },
    }, .{
        .vulkan = .{
            .name = "KhronosGroup/Vulkan-Headers",
            .host = .github,
            .ref = .tag,
        },
    });
    defer toolbox.deinit();

    const vulkan_path = try builder.build_root.join(builder.allocator, &.{
        "vulkan",
    });

    if (toolbox.getUpdate()) {
        try update(&toolbox, vulkan_path);
    }

    const lib = builder.addLibrary(.{
        .name = "vulkan",
        .root_module = std.Builder.Module.create(builder, .{
            .root_source_file = builder.addWriteFiles().add("empty.c", ""),
            .target = target,
            .optimize = optimize,
        }),
    });

    var vulkan_dir = try std.fs.openDirAbsolute(vulkan_path, .{
        .iterate = true,
    });
    defer vulkan_dir.close();

    var it = vulkan_dir.iterate();
    while (try it.next()) |*entry| {
        if (entry.kind == .directory) {
            toolbox.addHeader(lib, builder.pathJoin(&.{
                vulkan_path, entry.name,
            }), entry.name, &.{
                ".h", ".hpp",
            });
        }
    }

    builder.installArtifact(lib);
}
