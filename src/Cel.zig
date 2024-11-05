const Layer = @import("Layer.zig");
const Point = @import("Point.zig");
const CelType = @import("enums.zig").CelType;

layer: Layer,
cel_pos: Point,
opacity: u8,
cel_type: CelType,
z_index: i16,
pixels: []u8