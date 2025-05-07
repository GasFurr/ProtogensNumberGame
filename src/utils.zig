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

    const art = try file.readToEndAlloc(
        allocator,
        std.math.maxInt(usize),
    );
    defer allocator.free(art);

    std.debug.print("{s}\n", .{art});
}

pub fn clearTerminal() void {
    std.debug.print("\x1B[2J\x1B[H", .{}); // Clears screen and moves cursor to (0,0)
}

// Cryptographically safe seed generation. UNIX-ONLY!
pub fn getSecureSeed() !u32 {
    // reading /dev/urandom to get cryptosafe number.
    const seed_read = try std.fs.openFileAbsolute("/dev/urandom", .{ .mode = .read_only });
    defer seed_read.close(); // Cleanup

    // 8 bytes buffer
    var buffer: [8]u8 = undefined;

    // Reading until end of buffer
    try seed_read.reader().readNoEof(&buffer);

    // translating to u64
    const result = std.mem.bytesToValue(u32, &buffer);
    return result; // Passing seed.
}

pub fn random(at_least: u32, less_than: u32) !u32 {
    const seed = try getSecureSeed();
    var prng = std.Random.DefaultPrng.init(seed);

    const rand = prng.random();

    const generate = rand.intRangeLessThan(u32, at_least, less_than);
    return generate;
}
