//! This script should be attached to the player object so that the audio-source script
//! can mutate audio buffer volume according to the player position/distance.

const std = @import("std");
const sdl = @import("sdl");
const modules = @import("../modules/mod.zig");
const plugins = @import("../plugins/mod.zig");
const types = @import("../types/mod.zig");

const AudioListener = @This();

/// The volume of the audio to be played. Volume values range between 0.0 and 1.0.
volume: f32 = 1.0,

_script_strategy: modules.ScriptStrategy = modules.ScriptStrategy{
    .start = start,
    .update = update,
    .end = end,
},

_allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator) *AudioListener {
    var audioListener = try allocator.create(AudioListener);
    audioListener.volume = 1.0;
    audioListener._script_strategy = .{
        .start = start,
        .update = update,
        .end = end,
    };
    audioListener._allocator = allocator;
    return audioListener;
}

pub fn deinit(self: *AudioListener) void {
    self._allocator.destroy(self);
}

pub fn toScript(self: *AudioListener) modules.Script {
    return modules.Script{
        .name = "AudioListener",
        .strategy = &self._script_strategy,
    };
}

fn start(_: *modules.Script, _: *modules.Object) void {}

fn update(_: *modules.Script, _: *modules.Object, _: f32) void {}

fn end(_: *modules.Script, _: *modules.Object) void {}
