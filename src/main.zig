const std = @import("std");
const utils = @import("utils.zig");

// In zig declaration order doesn't matter.
// pub - makes function visible to other modules.
pub fn main() !void {
    // declares basic page_allocator. Not production-grade,
    // but just fine for this use.
    const allocator = std.heap.page_allocator;
    // Self explainatory
    utils.clearTerminal();
    // Rendering welcoming ascii art
    try utils.renderAscii(allocator, "resources/proto.txt");

    const number = try utils.random(1, 1000);
    std.debug.print("Random number is: {}", .{number});
    // Main game loop
    while (true) {}
}
