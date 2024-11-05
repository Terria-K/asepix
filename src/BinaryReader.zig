const std = @import("std");
const Point = @import("Point.zig");

reader: std.fs.File.Reader,
pub fn init(reader: std.fs.File.Reader) @This() {
    return .{ .reader = reader };
}

pub fn deinit(_: @This()) void {}

pub inline fn BYTE(self: @This()) !u8 {
    return try self.read(u8);
}
pub inline fn BYTES(self: @This(), comptime num: u64) ![]u8 {
    const buff: [num]u8 = undefined;
    _ = try self.reader.readAtLeast(buff, num);
    return buff;
}
pub inline fn WORD(self: @This()) !u16 {
    return try self.read(u16);
}
pub inline fn SHORT(self: @This()) !i16 {
    return try self.read(i16);
}
pub inline fn DWORD(self: @This()) !u32 {
    return try self.read(u32);
}
pub inline fn LONG(self: @This()) !i32 {
    return try self.read(i32);
}
pub inline fn FIXED(self: @This()) !i32 {
    return try self.read(i32);
}
pub inline fn FLOAT(self: @This()) !f32 {
    return try self.read(f32);
}
pub inline fn DOUBLE(self: @This()) !f64 {
    return try self.read(f64);
}
pub inline fn QWORD(self: @This()) !u64 {
    return try self.read(u64);
}
pub inline fn LONG64(self: @This()) !i64 {
    return try self.read(i64);
}
pub inline fn POINT(self: @This()) !Point {
    const x = try self.SHORT();    
    const y = try self.SHORT();
    return .{
        .x = x, .y = y
    };
}
pub inline fn STRING(self: @This(), allocator: std.mem.Allocator) ![]const u8 {
    const length = try self.WORD();
    const buff = try allocator.alloc(u8, @intCast(length));
    _ = try self.reader.readAtLeast(buff, length);
    return buff;
}

pub inline fn SKIP(self: @This(), comptime num: u64) !void {
    var buf: [num]u8 = undefined;
    var remaining = num;

    while (remaining > 0) {
        const amt = @min(remaining, num);
        try self.reader.readNoEof(buf[0..amt]);
        remaining -= amt;
    }
}

pub inline fn SKIP_DYN(self: @This(), num: u64) !void {
    try self.reader.skipBytes(num, .{ .buf_size = 4096 });
}

pub inline fn SEEK(self: @This(), num: u64) !void {
    try self.reader.context.seekTo(num);
}

pub fn read(self: @This(), comptime T: type) !T {
    const bitSize = @sizeOf(T);
    var buffer: [bitSize]u8 = undefined;
    const size = try self.reader.read(buffer[0..]);
    if (size < 1) {
        return error.EndOfStream;
    }
    return @as(T, @bitCast(buffer));
}

pub inline fn getPos(self: @This()) !u64 {
    return try self.reader.context.getPos();
}
