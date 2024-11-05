const LayerFlags = @import("flags.zig").LayerFlags;
const LayerType = @import("enums.zig").LayerType;
const BlendMode = @import("enums.zig").BlendMode;

flags: LayerFlags,
type: LayerType,
blend_mode: BlendMode,
child_level: u16,
opacity: u8,
layer_name: []const u8,
tileset_index: ?u32,

pub fn init(
    flags: LayerFlags, 
    layer_type: LayerType, 
    blend_mode: BlendMode, 
    child_level: u16, 
    opacity: u8, 
    tileset_index: ?u32, 
    layer_name: []const u8
) @This() {
    return .{
        .flags = flags,
        .type = layer_type,
        .blend_mode = blend_mode,
        .child_level = child_level,
        .opacity = opacity,
        .tileset_index = tileset_index,
        .layer_name = layer_name
    };
}