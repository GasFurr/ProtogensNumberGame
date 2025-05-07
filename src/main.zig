const std = @import("std");
const utils = @import("utils.zig");
// comptime T: type,b: []const T,a: []const T
// Global allocator.
pub const allocator = std.heap.page_allocator;

//  Data:
const Difficulty = enum {
    Easy,
    Medium,
    Hard,
    Chromium,
};
const GameState = enum {
    InMenu,
    ScoreScreen,
    DifficultyScreen,
    GameStarted,
    WinScreen,
    DebugMode,
    unexpected,
};
var debug: u32 = 0;
var score: u32 = 0;
var max_score: []const u8 = "0";
var current_state = GameState.InMenu;
var current_difficulty = Difficulty.Easy;
var main_loop: bool = true;
var game_loop: bool = false;

// In zig declaration order doesn't matter.
// pub - makes function visible to other modules.
pub fn main() !void {
    // Rendering welcome screen
    utils.clearTerminal();
    try utils.renderAscii(allocator, "resources/proto.txt");
    // Initialization stage
    max_score = try utils.parseMaxScore(allocator);
    defer allocator.free(max_score);

    try utils.waitForEnterKeyPress();
    std.debug.print("Enter pressed", .{});
    // Calling main menu;
    try mainGameLoop();
}

fn mainGameLoop() !void {
    while (main_loop == true) {
        switch (current_state) {
            GameState.InMenu => {
                utils.clearTerminal();
                // Drawing main menu
                try utils.renderAscii(allocator, "resources/menu.txt");
                if (debug == 1) {
                    std.debug.print("Debug mode is active, no scores!", .{});
                }
                // Activating input
                const input = try utils.readStdinLine(allocator);
                defer allocator.free(input);
                // Menu
                if (std.mem.eql(u8, input, "0")) {
                    break;
                } else if (std.mem.eql(u8, input, "1")) {
                    current_state = GameState.DifficultyScreen;
                } else if (std.mem.eql(u8, input, "2")) {
                    current_state = GameState.ScoreScreen;
                } else if (std.mem.eql(u8, input, "7")) {
                    current_state = GameState.DebugMode;
                }

                // -- End of Main Menu -- //
            },
            GameState.ScoreScreen => {
                utils.clearTerminal();
                if (score == 0) {
                    std.debug.print("Play a game first! \n", .{});
                } else {
                    std.debug.print("Your last steps count:{} \n", .{score});
                }
                std.debug.print("Your least steps count: {s}\n", .{max_score});
                std.debug.print("Press enter to go back...", .{});
                if (debug == 1) {
                    try utils.renderAscii(allocator, "resources/scoreDebug.txt");
                }
                try utils.waitForEnterKeyPress();
                current_state = GameState.InMenu;
            },
            GameState.DifficultyScreen => {
                utils.clearTerminal();
                try utils.renderAscii(allocator, "resources/startgame.txt");
                const choice = try utils.readStdinLine(allocator);
                defer allocator.free(choice);
                if (std.mem.eql(u8, choice, "0")) {
                    break;
                } else if (std.mem.eql(u8, choice, "1")) {} else if (std.mem.eql(u8, choice, "2")) {} else if (std.mem.eql(u8, choice, "3")) {}
            },
            GameState.GameStarted => {
                utils.clearTerminal();
                try GameStarted(current_difficulty);
                main_loop = false;
            },
            GameState.WinScreen => {
                // Drawing art + info + art in 3 stages
                try utils.renderAscii(allocator, "resources/winart.txt"); //image
                std.debug.print("Your made {} guesses!", .{score});
                std.debug.print("Least guesses {s}", .{max_score});
                try utils.renderAscii(allocator, "resources/winart2.txt"); //text
                // Input + deallocation
                const input = try utils.readStdinLine(allocator);
                defer allocator.free(input);
                // Menu
                if (std.mem.eql(u8, input, "0")) {
                    break;
                } else if (std.mem.eql(u8, input, "1")) {
                    current_state = GameState.DifficultyScreen;
                } else if (std.mem.eql(u8, input, "2")) {
                    current_state = GameState.InMenu;
                } else if (std.mem.eql(u8, input, "3")) {
                    utils.resetMaxScore();
                }
                // -- End of WinScreen -- //
            },
            GameState.DebugMode => {
                std.debug.print("Do you want to enter debug mode?\n [Y/N]", .{});
                const input = try utils.readStdinLine(allocator);
                defer allocator.free(input);

                if (std.mem.eql(u8, input, "Y")) {
                    debug = 1;
                    current_state = GameState.InMenu;
                } else {
                    debug = 0;
                    current_state = GameState.InMenu;
                }
                // -- End of Debug Mode Screen. -- //
            },
            GameState.unexpected => {
                std.debug.print("If you are a cheater - why? \n If it's a bug.. Idk, restart the program", .{});
            },
        }
    }
}

pub fn GameStarted(difficulty: Difficulty) !void {
    if (debug == 0) {
        utils.clearTerminal();
        switch (difficulty) {
            Difficulty.Easy => {
                game_loop = true;
            },
            Difficulty.Medium => {
                game_loop = true;
            },
            Difficulty.Hard => {
                game_loop = true;
            },
            Difficulty.Chromium => {
                game_loop = true;
            },
        }
        while (game_loop == true) {
            break;
        }

        utils.clearTerminal();
        main_loop = true;
        current_state = GameState.unexpected;
        return;
    }
}
