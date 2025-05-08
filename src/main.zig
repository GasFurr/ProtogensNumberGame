const std = @import("std");
const utils = @import("utils.zig");
const print = std.debug.print;
const strcompare = std.mem.eql;
// Global allocator.
pub const allocator = std.heap.page_allocator;

//  Difficulty data
const Difficulty = enum {
    Easy,
    Medium,
    Hard,
    Chromium,
};
// Game states
const GameState = enum {
    InMenu,
    ScoreScreen, // "scores" menu
    DifficultyScreen,
    GameStarted, // Pre-starting sequence
    WinScreen,
    DebugMode, // Debug menu
    unexpected, // When something unexpected happens.
};
// Game data:
var debug: u32 = 0; // Debug mode flag
var score: u32 = 0; // Score counter
var debug_score: u32 = 0; // Debug score counter
var max_score: []const u8 = "0"; // Max score counter
var current_state = GameState.InMenu; // Current game state
var current_difficulty = Difficulty.Easy; // Current Difficulty
var main_loop: bool = true; // Is main loop active?
var game_loop: bool = false; // Is game loop active?
var new_max_score: bool = false; // Is score > max_score?

// Main function
pub fn main() !void {
    // Rendering welcome screen
    utils.clearTerminal();
    try utils.renderAscii(allocator, "resources/proto.txt");
    // Initialization stage
    // Checking file integrity.
    try utils.initializeResources();
    // Parsing max score.
    max_score = try utils.parseMaxScore(allocator);
    defer allocator.free(max_score); // Freeing memory.

    try utils.waitForEnterKeyPress(); // Self-explainatory fn
    print("Enter pressed", .{}); //std.debug.print abbreviated
    // Calling main menu;
    try MenuLoop();
}

fn MenuLoop() !void {
    // Is main loop active?
    while (main_loop == true) {
        switch (current_state) {
            // Is GameState - in menu?
            GameState.InMenu => {
                utils.clearTerminal();
                new_max_score = false;
                // Drawing main menu
                try utils.renderAscii(allocator, "resources/menu.txt");
                if (debug == 1) {
                    print("Debug mode is active, no scores!\n", .{});
                    print("Press 8 to reset all scores.", .{});
                }
                // Activating input
                const input = try utils.readStdinLine(allocator);
                defer allocator.free(input);
                // Menu

                if (strcompare(u8, input, "0")) {
                    main_loop = false;
                    return;
                } else if (strcompare(u8, input, "1")) {
                    current_state = GameState.DifficultyScreen;
                } else if (strcompare(u8, input, "2")) {
                    current_state = GameState.ScoreScreen;
                } else if (strcompare(u8, input, "7")) {
                    current_state = GameState.DebugMode;
                } else if (debug == 1 and strcompare(u8, input, "8")) {
                    try utils.resetMaxScore("resources/score");
                    try utils.resetMaxScore("resources/scoreDebug");
                }

                // -- End of Main Menu -- //
            },
            // Is GameState - score screen?
            GameState.ScoreScreen => {
                utils.clearTerminal();
                if (score == 0 and debug == 0) {
                    print("Play a game first! \n", .{});
                } else {
                    print("Your last steps count:{} \n", .{score});
                }
                const current_max = try utils.parseMaxScore(allocator);
                defer allocator.free(current_max);
                print("Your least steps count: {s}\n", .{current_max});
                print("Press enter to go back...\n", .{});
                if (debug == 1) {
                    print("Debug score:", .{});
                    try utils.renderAscii(allocator, "resources/scoreDebug");
                }
                try utils.waitForEnterKeyPress();
                current_state = GameState.InMenu;
                // -- End of Score Menu -- //
            },
            // Is GameState - difficulty screen?
            GameState.DifficultyScreen => {
                utils.clearTerminal();
                try utils.renderAscii(allocator, "resources/startgame.txt");
                const choice = try utils.readStdinLine(allocator);
                defer allocator.free(choice);
                if (strcompare(u8, choice, "0")) {
                    break;
                } else if (strcompare(u8, choice, "1")) {
                    current_difficulty = Difficulty.Easy;
                    current_state = GameState.GameStarted;
                } else if (strcompare(u8, choice, "2")) {
                    current_difficulty = Difficulty.Medium;
                    current_state = GameState.GameStarted;
                } else if (strcompare(u8, choice, "3")) {
                    current_difficulty = Difficulty.Hard;
                    current_state = GameState.GameStarted;
                } else if (strcompare(u8, choice, "4")) {
                    current_difficulty = Difficulty.Chromium;
                    current_state = GameState.GameStarted;
                }
            },
            // Is GameState - Game Started?
            GameState.GameStarted => {
                utils.clearTerminal();
                try gameStarted(current_difficulty);
            },
            // Is GameState - Win Screen?
            GameState.WinScreen => {
                // Drawing art + info + art in 3 stages
                const current_max = try utils.parseMaxScore(allocator);
                defer allocator.free(current_max);
                try utils.renderAscii(allocator, "resources/winart.txt"); //image
                print("Your made {} guesses!\n", .{score});
                print("Least guesses {s}\n", .{current_max});
                try utils.renderAscii(allocator, "resources/winart2.txt"); //text
                // Input + deallocation
                const input = try utils.readStdinLine(allocator);
                defer allocator.free(input);
                // Menu
                if (strcompare(u8, input, "0")) {
                    break;
                } else if (strcompare(u8, input, "1")) {
                    current_state = GameState.DifficultyScreen;
                } else if (strcompare(u8, input, "2")) {
                    current_state = GameState.InMenu;
                } else if (strcompare(u8, input, "3")) {
                    try utils.resetMaxScore("resources/score");
                    if (debug == 1) {
                        try utils.resetMaxScore("resources/scoreDebug");
                    }
                }
                // -- End of WinScreen -- //
            },
            // Is GameState - debug mode?
            GameState.DebugMode => {
                print("Do you want to enter debug mode?\n [Y/N]", .{});
                const input = try utils.readStdinLine(allocator);
                defer allocator.free(input);
                // Comparing input. If it's 'Y' or 'y' - enables debug mode
                if (strcompare(u8, input, "Y") or strcompare(u8, input, "y")) {
                    debug = 1;
                    current_state = GameState.InMenu;
                } else { // If it's anything else just do nothing
                    debug = 0;
                    current_state = GameState.InMenu;
                }
                // -- End of Debug Mode Screen. -- //
            },
            // In case of failure.
            GameState.unexpected => {
                print("If you are a cheater - why? \n If it's a bug.. Idk, restart the program", .{});
                try utils.waitForEnterKeyPress();
                current_state = GameState.InMenu;
            },
        }
    }
}
// Real main game loop lol.
pub fn gameStarted(difficulty: Difficulty) !void {
    // Resetting score
    score = 0;
    debug_score = 0;
    // Creating variable for number.
    var number: u32 = 0;
    utils.clearTerminal();
    // Difficulty switch;
    switch (difficulty) {
        Difficulty.Easy => {
            print("Wait a second, i am thinking...\n", .{});
            // Calls utils.random to generate number
            number = try utils.random(1, 101);
            // Sleeps for roughly 1.2 seconds
            std.time.sleep(1254311000);
            // Starting game loop
            print("Yeah, i am ready.\n", .{});
            game_loop = true;
        },
        Difficulty.Medium => {
            game_loop = true;
            // todo: medium difficulty
        },
        Difficulty.Hard => {
            game_loop = true;
            // todo: hard difficulty
        },
        Difficulty.Chromium => {
            game_loop = false;
            try ChromiumDifficulty();
            number = 1;
        },
    }

    // Check for debugging:
    if (debug == 1) {

        // If debug it will write the generated number;
        print("DEBUG: The number is {}\n", .{number});
    } else if (number == 0) {

        // If number == 0 means it's not generated,
        // so throws GameState unexpected and returns to MenuLoop;
        utils.clearTerminal();
        current_state = GameState.unexpected;
        return;
    } else {
        // If everything fine it starts the game.
        print("Let's start!\n", .{});
    }

    // Game loop.
    while (game_loop == true) {
        // Updates score every move
        // (including first one so score can't be less than 1)
        score += 1; // Todo - rework debug score system.
        if (debug == 1) {
            debug_score += 1;
        }
        // Waiting for the guess
        print("Your guess:", .{});
        const input = try utils.readStdinLine(allocator);
        defer allocator.free(input);
        // Converting guess to intager.
        const guess = std.fmt.parseInt(u32, input, 10) catch {
            // If there's words in the guess - it will ignore it.
            print("\nIt's not a number! (at least it's hard for me to find it)", .{});
            print("\nI will not count that as guess. Your score is still {}\n", .{score});
            score -= 1; // Only count valid attempts
            continue;
        };
        // If guess is fine - check it.
        if (guess == number) {
            // When guess equals number
            utils.clearTerminal();

            if (score == 1) {
                // When it's first move
                print("\nWow, first try!\n", .{});
            } else {
                // When it's any other time
                print("\nYou win this time.\n", .{});
            }
            // Prints the number
            print("\nThe number was {}\n", .{number});

            // Update max score if needed
            const current_max = try std.fmt.parseInt(u32, max_score, 10);
            // Settin up current_max, try to parse intager from it.
            if ((score < current_max or current_max == 0) and debug == 0) {
                // Try set max score in the file
                try utils.setMaxScore(score, "resources/score");
                // Set's new_max_score true. For now not used?
                new_max_score = true;
            }

            // Throws player to win screen, stops game loop, checks again if
            // main loop is active (and activating it)
            // and then return from function.
            current_state = GameState.WinScreen;
            game_loop = false;
            main_loop = true;
            return;
        } else if (guess > number) {
            // If guess is bigger than the number
            print("\nI'm not eating that much! >w<\n", .{});
            continue; // Jumping to next round of the loop
        } else if (guess < number) {
            // If guess is lower than the number
            print("\nI would starve if it was true! owo\n", .{});
            continue; // And jumping to next round again
        }
    }
    // Making sure that game loop stopped, main loop activated
    // and setting game state "in menu"
    defer {
        game_loop = false;
        main_loop = true;
        current_state = GameState.InMenu;
    }
}

// Experimental ultra-hard difficulty, not ready for now.
pub fn ChromiumDifficulty() !void {
    print("In work...", .{});
    print("   o w o   ", .{});
    try utils.waitForEnterKeyPress();
    current_state = GameState.InMenu;
}
