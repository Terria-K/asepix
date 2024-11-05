const std = @import("std");
const Cel = @import("Cel.zig");

cels: std.ArrayList(Cel),

pub fn init(allocator: std.mem.Allocator) @This() {
    return .{ .cels = std.ArrayList(Cel).init(allocator) };
}

pub fn deinit(self: @This()) void {
    self.cels.deinit();
}