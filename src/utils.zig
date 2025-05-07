const std = @import("std");

// Zig requires explictic memory management.
// We pass allocator as a parameter for the function.
pub fn readStdinLine(allocator: std.mem.Allocator) ![]const u8 {
    const stdin = std.io.getStdIn();
    var buffered_reader = std.io.bufferedReader(stdin.reader());
    const reader = buffered_reader.reader();

    // Dynamically allocate memory as reading and putting it in "line" immutable variable.
    // Basically reads until delimiter no matter the size. Returns if allocation or i/o fails.
    const line = try reader.readUntilDelimiterAlloc(allocator, '\n', std.math.maxInt(usize));

    // Windows compatibility: Trim trailing \r
    return std.mem.trimRight(u8, line, &[_]u8{'\r'});
}
// readStdinLine can return error union because ![]const u8

// Read ASCII-art from file and write it on screen
pub fn renderAscii(allocator: std.mem.Allocator, path: []const u8) !void {
    // Opening file on passed path.
    const file = try std.fs.cwd().openFile(path, .{ .mode = .read_only });
    defer file.close();

    const art = try .file.readToEndAlloc(
        allocator,
        std.math.maxInt(usize),
    );
    defer allocator.free();

    std.debug.print("{s}\n", .{art});
}
