const std = @import("std");
const LayerFlags = @import("flags.zig").LayerFlags;
const BinaryReader = @import("BinaryReader.zig");
const Point = @import("Point.zig");
const Color = @import("Color.zig");
const Tag = @import("Tag.zig");
const Cel = @import("Cel.zig");
const Frame = @import("Frame.zig");
const Layer = @import("Layer.zig");
const enums = @import("enums.zig");
const LoopDirection = enums.LoopDirection;
const LayerType = enums.LayerType;
const Format = enums.Format;
const BlendMode = enums.BlendMode;
const CelType = enums.CelType;
const ChunkType = enums.ChunkType;


width: u16,
height: u16,
allocator: std.mem.Allocator,
layers: std.ArrayList(Layer),

frames: []Frame = undefined,
tags: []Tag = undefined,
palletes: []Color = undefined,

pub fn init(allocator: std.mem.Allocator) @This() {
    return .{ .width = 0, .height = 0, .allocator = allocator, .layers = std.ArrayList(Layer).init(allocator) };
}

pub fn deinit(self: @This()) void {
    for (0..self.frames.len) |i| {
        self.frames[i].deinit();
    }
    self.allocator.free(self.frames);
    self.allocator.free(self.palletes);
}

pub fn load(self: *@This(), path: []const u8) !void {
    self.palletes = try self.allocator.alloc(Color, 0);
    self.tags = try self.allocator.alloc(Tag, 0);
    self.frames = try self.allocator.alloc(Frame, 0);

    const cwd = std.fs.cwd();
    const file = cwd.openFile(path, .{}) catch {
        std.log.err("Cannot open a file.", .{});
        return;
    };
    defer file.close();

    const reader = BinaryReader.init(file.reader());
    defer reader.deinit();
    _ = try reader.DWORD(); // Filesize
    const magic = try reader.WORD();

    if (magic != 0xA5E0) {
        // We must allocate this or else we have some undefined behavior
        std.log.err("Invalid magic number.", .{});
        return;
    }

    const frames = try reader.WORD();
    self.width = try reader.WORD();
    self.height = try reader.WORD();
    const format: Format = @enumFromInt(try reader.WORD());

    _ = try reader.DWORD(); // flags
    _ = try reader.WORD(); // Speed
    _ = try reader.DWORD(); // 0
    _ = try reader.DWORD(); // 0
    _ = try reader.BYTE(); // palette entry
    try reader.SKIP(3);
    _ = try reader.WORD(); // num of colors
    _ = try reader.BYTE(); // pixel width
    _ = try reader.BYTE(); // pixel height
    _ = try reader.SHORT(); // X position of grid
    _ = try reader.SHORT(); // Y position of grid
    _ = try reader.WORD(); // grid width
    _ = try reader.WORD(); // grid height
    try reader.SKIP(84);

    self.frames = try self.allocator.realloc(self.frames, @intCast(frames));
    var pixel_buffer = try self.allocator.alloc(u8, self.width * self.height * (@intFromEnum(format) / 8));

    for (0..frames) |i| {
        self.frames[i] = Frame.init(self.allocator);
        _ = try reader.DWORD();
        const frame_magic = try reader.WORD();
        if (frame_magic != 0xF1FA) {
            std.log.err("Invalid frame magic number.", .{});
            return;
        }

        const old_chunk = try reader.WORD();
        _ = try reader.WORD(); // duration
        try reader.SKIP(2);
        var new_chunk: usize = @intCast(try reader.DWORD());

        if (new_chunk == 0) {
            new_chunk = old_chunk;
        }

        for (0..new_chunk) |_| {
            const pos = try reader.getPos();
            const chunk_size = try reader.DWORD();
            const chunk_type: ChunkType = @enumFromInt(try reader.WORD());
            const chunk_end_data = pos + chunk_size;

            switch (chunk_type) {
                ChunkType.LayerChunk => {
                    const flags: LayerFlags = @bitCast(try reader.WORD());
                    const t: LayerType = @enumFromInt(try reader.WORD());
                    const child_level = try reader.WORD();
                    _ = try reader.WORD();
                    _ = try reader.WORD();
                    const blend_mode: BlendMode = @enumFromInt(try reader.WORD());
                    const opacity = try reader.BYTE();
                    try reader.SKIP(3);
                    const layer_name = try reader.STRING(self.allocator);
                    var tileset_index: ?u32 = 25565;
                    if (t == LayerType.Tilemap) {
                        tileset_index = try reader.DWORD();
                    }

                    const layer = Layer.init(flags, t, blend_mode, child_level, opacity, tileset_index, layer_name);
                    try self.layers.append(layer);
                },
                ChunkType.CelChunk => {
                    const layer_index = try reader.WORD();
                    const layer = self.layers.items[layer_index];
                    const cel_pos = try reader.POINT();
                    const cel_opacity = try reader.BYTE();
                    const cel_type: CelType = @enumFromInt(try reader.WORD());
                    const cel_z_index = try reader.SHORT();

                    if (cel_type == CelType.CompressedTilemap) {
                        try reader.SEEK(chunk_end_data);
                        continue;
                    }

                    var cel: Cel = .{ 
                        .cel_pos = cel_pos, 
                        .opacity = cel_opacity, 
                        .cel_type = cel_type,
                        .layer = layer,
                        .z_index = cel_z_index,
                        .pixels = undefined
                    };

                    try reader.SKIP(5);

                    if (cel_type == CelType.LinkedCel) {
                        const frame_index = try reader.WORD();
                        const cels = self.frames[frame_index].cels;
                        for (0..cels.items.len) |j| {
                            const tcel = cels.items[j];
                            cel.pixels = tcel.pixels;
                        }

                        try reader.SEEK(chunk_end_data);
                        continue;
                    }
                    const img_width = try reader.WORD();
                    const img_height = try reader.WORD();
                    const pixels = try self.allocator.alloc(Color, img_width * img_height);
                    const decompressed_size = img_width * img_height * (@intFromEnum(format) / 8);

                    if (pixel_buffer.len < decompressed_size) {
                        pixel_buffer = try self.allocator.realloc(pixel_buffer, decompressed_size);
                    }

                    switch (cel_type) {
                        CelType.RawImageData => {
                            _ = try reader.reader.readAtLeast(pixel_buffer, decompressed_size);
                        },
                        CelType.CompressedImage => {
                            var decompressor = std.compress.zlib.decompressor(reader.reader);
                            _ = try decompressor.read(pixel_buffer);
                        },
                        else => {}
                    }

                    switch (format) {
                        Format.RGBA => {
                            var p: usize = 0;
                            var pb: usize = 0;

                            while (p < pixels.len) {
                                pixels[p] = .{ .r = pixel_buffer[pb], .g = pixel_buffer[pb + 1], 
                                    .b = pixel_buffer[pb + 2], .a = pixel_buffer[pb + 3]};
                                p += 1;
                                pb += 4;
                            }
                        },
                        Format.Grayscale => {
                            var p: usize = 0;
                            var pb: usize = 0;

                            while (p < pixels.len) {
                                pixels[p] = .{ .r = pixel_buffer[pb], .g = pixel_buffer[pb], 
                                    .b = pixel_buffer[pb], .a = pixel_buffer[pb + 1]};
                                p += 1;
                                pb += 2;
                            }
                        },
                        Format.Indexed => {}
                    }
                },
                ChunkType.TagsChunk => {
                    const num_tags = try reader.WORD();
                    if (num_tags > self.tags.len) {
                        self.tags = try self.allocator.realloc(self.tags, num_tags);
                    }
                    try reader.SKIP(8);

                    for (0..num_tags) |j| {
                        const from = try reader.WORD();
                        const to = try reader.WORD();
                        const loop_direction: LoopDirection = @enumFromInt(try reader.BYTE());
                        const repeat = try reader.WORD();
                        try reader.SKIP(10);
                        const tag_name = try reader.STRING(self.allocator);
                        self.tags[j] = .{ .name = tag_name, .from = from, .to = to, .loop_direction = loop_direction, .repeat_times = repeat };
                    }
                },
                ChunkType.PaletteChunk => {
                    const len = try reader.DWORD();
                    const first = try reader.DWORD();
                    const last = try reader.DWORD();
                    try reader.SKIP(8);

                    if (len > self.palletes.len) {
                        self.palletes = try self.allocator.realloc(self.palletes, len);
                    }

                    var p = first;
                    while (p <= last) {
                        const flags = try reader.WORD();
                        self.palletes[p] = .{ 
                            .r = try reader.BYTE(), 
                            .g = try reader.BYTE(), 
                            .b = try reader.BYTE(), 
                            .a = try reader.BYTE() 
                        };

                        if ((flags & p) != 0) {
                            _ = try reader.STRING(self.allocator);
                        }
                        p += 1;
                    }
                },
                else => {

                }
            }
            try reader.SEEK(chunk_end_data);
        }
    }
}

