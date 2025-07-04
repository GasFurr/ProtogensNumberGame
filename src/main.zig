const std = @import("std");
const utils = @import("utils.zig");

//  Difficulty data
const Difficulty = enum {
    Easy,
    Medium,
    Hard,
    Extreme,
};
// Game states
const GameState = enum { Welcome, MenuMain, MenuNewGame, MenuGameInfo, MenuHighscores, MenuDebug, ScreenGameplay, ScreenLose, ScreenWin, ScreenNewRecord, UNEXPECTED };

// Game context.
const Game = struct {
    state: GameState,
    difficulty: Difficulty,
    score: u32 = 0,
    attempts: u32 = 0,
    max_score: u32 = 0,
    // debug mode flag
    debug: bool = false,
    // calculate in runtime.
    pub fn isNewHighScore(self: *const Game) bool {
        return self.score > self.max_score;
    }
};

pub fn main() !void {}
