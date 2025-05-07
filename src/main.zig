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
var debug_score: u32 = 0;
var max_score: []const u8 = "0";
var current_state = GameState.InMenu;
var current_difficulty = Difficulty.Easy;
var main_loop: bool = true;
var game_loop: bool = false;
var new_max_score: bool = false;

// In zig declaration order doesn't matter.
// pub - makes function visible to other modules.
pub fn main() !void {
    // Rendering welcome screen
    utils.clearTerminal();
    try utils.renderAscii(allocator, "resources/proto.txt");
    // Initialization stage
    try utils.initializeResources();
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
                new_max_score = false;
                // Drawing main menu
                try utils.renderAscii(allocator, "resources/menu.txt");
                if (debug == 1) {
                    std.debug.print("Debug mode is active, no scores!\n", .{});
                    std.debug.print("Press 8 to reset all scores.", .{});
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
                } else if (debug == 1 and std.mem.eql(u8, input, "8")) {
                    try utils.resetMaxScore("resources/score");
                    try utils.resetMaxScore("resources/scoreDebug");
                }

                // -- End of Main Menu -- //
            },
            GameState.ScoreScreen => {
                utils.clearTerminal();
                if (score == 0 and debug == 0) {
                    std.debug.print("Play a game first! \n", .{});
                } else {
                    std.debug.print("Your last steps count:{} \n", .{score});
                }
                max_score = try utils.parseMaxScore(allocator);
                defer allocator.free(max_score);
                std.debug.print("Your least steps count: {s}\n", .{max_score});
                std.debug.print("Press enter to go back...\n", .{});
                if (debug == 1) {
                    std.debug.print("Debug score:", .{});
                    try utils.renderAscii(allocator, "resources/scoreDebug");
                }
                try utils.waitForEnterKeyPress();
                current_state = GameState.InMenu;
                // -- End of Score Menu -- //
            },
            GameState.DifficultyScreen => {
                utils.clearTerminal();
                try utils.renderAscii(allocator, "resources/startgame.txt");
                const choice = try utils.readStdinLine(allocator);
                defer allocator.free(choice);
                if (std.mem.eql(u8, choice, "0")) {
                    break;
                } else if (std.mem.eql(u8, choice, "1")) {
                    current_difficulty = Difficulty.Easy;
                    current_state = GameState.GameStarted;
                } else if (std.mem.eql(u8, choice, "2")) {
                    current_difficulty = Difficulty.Medium;
                    current_state = GameState.GameStarted;
                } else if (std.mem.eql(u8, choice, "3")) {
                    current_difficulty = Difficulty.Hard;
                    current_state = GameState.GameStarted;
                } else if (std.mem.eql(u8, choice, "4")) {
                    current_difficulty = Difficulty.Chromium;
                    current_state = GameState.GameStarted;
                }
            },
            GameState.GameStarted => {
                utils.clearTerminal();
                try GameStarted(current_difficulty);
            },
            GameState.WinScreen => {
                // Drawing art + info + art in 3 stages
                max_score = try utils.parseMaxScore(allocator);
                defer allocator.free(max_score);
                try utils.renderAscii(allocator, "resources/winart.txt"); //image
                std.debug.print("Your made {} guesses!\n", .{score});
                std.debug.print("Least guesses {s}\n", .{max_score});
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
                    try utils.resetMaxScore("resources/score");
                    if (debug == 1) {
                        try utils.resetMaxScore("resources/scoreDebug");
                    }
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
                try utils.waitForEnterKeyPress();
                current_state = GameState.InMenu;
            },
        }
    }
}

pub fn GameStarted(difficulty: Difficulty) !void {
    score = 0;
    debug_score = 0;
    var number: u32 = 0;
    if (true) {
        utils.clearTerminal();
        switch (difficulty) {
            Difficulty.Easy => {
                std.debug.print("Wait a second, i am thinking...\n", .{});
                number = try utils.random(1, 101);
                std.time.sleep(1254311000);
                std.debug.print("Yeah, i am ready.\n", .{});
                game_loop = true;
            },
            Difficulty.Medium => {
                game_loop = true;
            },
            Difficulty.Hard => {
                game_loop = true;
            },
            Difficulty.Chromium => {
                game_loop = false;
                try ChromiumDifficulty();
                number = 1;
            },
        }

        if (debug == 1) {
            std.debug.print("DEBUG: The number is {}\n", .{number});
        } else if (number == 0) {
            utils.clearTerminal();
            current_state = GameState.unexpected;
            return;
        } else {
            std.debug.print("Let's start!\n", .{});
        }
        // Game loop.
        while (game_loop == true) {
            score += 1;
            if (debug == 1) {
                debug_score += 1;
            }
            std.debug.print("Your guess:", .{});
            const input = try utils.readStdinLine(allocator);
            defer allocator.free(input);

            const guess = std.fmt.parseInt(u32, input, 10) catch {
                std.debug.print("\nIt's not a number! (at least it's hard for me to find it)", .{});
                std.debug.print("\nI will not count that as guess. Your score is still {}\n", .{score});
                score -= 1; // Only count valid attempts
                continue;
            };

            if (guess == number) {
                utils.clearTerminal();
                if (score == 1) {
                    std.debug.print("\nWow, first try!\n", .{});
                } else {
                    std.debug.print("\nYou win this time.\n", .{});
                }
                std.debug.print("\nThe number was {}\n", .{number});

                // Update max score if needed
                const current_max = try std.fmt.parseInt(u32, max_score, 10);
                if ((score < current_max or current_max == 0) and debug == 0) {
                    try utils.setMaxScore(score, "resources/score");
                    new_max_score = true;
                }

                current_state = GameState.WinScreen;
                game_loop = false;
                main_loop = true;
                return;
            } else if (guess > number) {
                std.debug.print("\nI'm not eating that much! >w<\n", .{});
                continue;
            } else if (guess < number) {
                std.debug.print("\nI would starve if it was true! owo\n", .{});
                continue;
            }
        }
    }

    defer {
        game_loop = false;
        main_loop = true;
        current_state = GameState.InMenu;
    }
}

pub fn ChromiumDifficulty() !void {
    std.debug.print("In work...", .{});
    std.debug.print("   o w o   ", .{});
    try utils.waitForEnterKeyPress();
    current_state = GameState.InMenu;
}
