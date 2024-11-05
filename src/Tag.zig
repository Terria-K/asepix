const LoopDirection = @import("enums.zig").LoopDirection;

name: []const u8,
from: i32,
to: i32,
loop_direction: LoopDirection,
repeat_times: u16