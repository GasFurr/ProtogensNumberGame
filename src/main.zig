const std = @import("std");
const utils = @import("utils.zig");

// In zig declaration order doesn't matter.
// pub - makes function visible to other modules.
pub fn main() !void {
    // declares basic page_allocator. Not production-grade,
    // but just fine for this use.
    const allocator = std.heap.page_allocator;
    std.debug.print("\x1B[2J\x1B[H", .{}); // Clears screen and moves cursor to (0,0)

    try utils.renderAscii(allocator, "resources/proto.txt");

    while (true) {
        const input = try utils.readStdinLine(allocator);
        // Cleanup even if we out of scope to early.
        defer allocator.free(input);
    }
}
