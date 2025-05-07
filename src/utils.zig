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
pub fn waitForEnterKeyPress() !void {
    // Read until newline (Enter key)
    const reader = std.io.getStdIn().reader();
    while (true) {
        const byte = try reader.readByte();
        if (byte == '\n') break;
    }
}

pub fn parseMaxScore(allocator: std.mem.Allocator) ![]const u8 {
    // Opening score file
    const file = try std.fs.cwd().openFile("resources/score", .{ .mode = .read_only });
    defer file.close(); // cleanup

    //Reading to end of allocator
    const data = try file.readToEndAlloc(
        allocator,
        std.math.maxInt(usize),
    );

    _ = std.fmt.parseInt(u32, data, 10) catch {
        std.debug.print("Warning: Invalid score data, resetting to 0\n", .{});
        return try allocator.dupe(u8, "0");
    };

    return data;
}

pub fn createFileIfNotExists(path: []const u8, default_content: []const u8) !void {
    const dir_path = std.fs.path.dirname(path) orelse ".";

    // Create parent directories recursively
    try std.fs.cwd().makePath(dir_path);

    // Try to open existing file
    const file = std.fs.cwd().openFile(path, .{ .mode = .read_only }) catch |err| switch (err) {
        error.FileNotFound => {
            // Create new file with default content
            const new_file = try std.fs.cwd().createFile(path, .{});
            defer new_file.close();
            try new_file.writeAll(default_content);
            return;
        },
        else => return err, // Propagate other errors
    };

    // Close file if it existed
    defer file.close();
}

pub fn setMaxScore(score: u32, path: []const u8) !void {
    try ensureDirectoryExists(path);

    const file = try std.fs.cwd().createFile(path, .{ .truncate = true });
    defer file.close();

    var buffer: [12]u8 = undefined;
    const score_str = try std.fmt.bufPrint(&buffer, "{d}", .{score});
    try file.writeAll(score_str);
}

pub fn resetMaxScore(path: []const u8) !void {
    try ensureDirectoryExists(path);

    const file = try std.fs.cwd().createFile(path, .{ .truncate = true });
    defer file.close();
    try file.writeAll("0");
}

fn ensureDirectoryExists(path: []const u8) !void {
    if (std.fs.path.dirname(path)) |dir_path| {
        try std.fs.cwd().makePath(dir_path);
    }
}

pub fn initializeResources() !void {
    try createFileIfNotExists("resources/score", "0");
    try createFileIfNotExists("resources/scoreDebug", "DEBUG SCORES\n");
}
