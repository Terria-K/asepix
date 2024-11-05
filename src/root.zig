const std = @import("std");

pub const Aseprite = @import("Aseprite.zig");
pub const BinaryReader = @import("BinaryReader.zig");
pub const Color = @import("Color.zig");
pub const Point = @import("Point.zig");
pub const Tag = @import("Tag.zig");
pub const Cel = @import("Cel.zig");
pub const Frame = @import("Frame.zig");
pub const Layer = @import("Layer.zig");

const enums = @import("enums.zig");
pub const LoopDirection = enums.LoopDirection;
pub const LayerType = enums.LayerType;
pub const Format = enums.Format;
pub const BlendMode = enums.BlendMode;
pub const CelType = enums.CelType;
pub const ChunkType = enums.ChunkType;

pub fn loadAseprite(allocator: std.mem.Allocator, comptime path: []const u8) !Aseprite {
    var ase = Aseprite.init(allocator);
    try ase.load(path);
    return ase;
}

test "Ase test" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    var ase = try loadAseprite(arena.allocator(), "test/ball.aseprite");
    defer ase.deinit();
}