const std = @import("std");

// Function to read a line from stdin (public API)
pub fn readStdinLine(allocator: std.mem.Allocator) ![]const u8 {
    const stdin = std.io.getStdIn();
    var buffered_reader = std.io.bufferedReader(stdin.reader());
    const reader = buffered_reader.reader();

    // Read until newline with dynamic allocation
    const line = try reader.readUntilDelimiterAlloc(allocator, '\n', std.math.maxInt(usize));

    // Windows compatibility: Trim trailing \r
    return std.mem.trimRight(u8, line, &[_]u8{'\r'});
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // Use the function
    const input = try readStdinLine(allocator);
    defer allocator.free(input); // Cleanup

    std.debug.print("You entered: '{s}'\n", .{input});
}
