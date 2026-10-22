//! Loads and plays any audio file by using the AudioTrack struct.

const std = @import("std");
const sdl = @import("sdl");
const modules = @import("../modules/mod.zig");
const plugins = @import("../plugins/mod.zig");
const types = @import("../types/mod.zig");

const AudioSource = @This();

path: []const u8,
autoplay: bool = false,
loop: bool = false,

_volume: f32 = 1.0,
_track: ?*modules.AudioTrack = null,

_script_strategy: modules.ScriptStrategy = modules.ScriptStrategy{
    .start = start,
    .update = update,
    .end = end,
},

_allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator, config: struct {
    path: []const u8 = "",
    loop: bool = false,
    autoplay: bool = false,
}) !*AudioSource {
    var audioSource = try allocator.create(AudioSource);
    audioSource.path = config.path;
    audioSource.loop = config.loop;
    audioSource.autoplay = config.autoplay;
    audioSource._volume = 1.0;
    audioSource._track = try modules.PluginManager.get(
        plugins.AudioManager,
        "AudioManager",
    ).?.newTrack(config.path);
    audioSource._script_strategy = .{
        .start = start,
        .update = update,
        .end = end,
    };
    audioSource._allocator = allocator;
    return audioSource;
}

pub fn deinit(self: *AudioSource) void {
    self._allocator.destroy(self);
}

pub fn toScript(self: *AudioSource) modules.Script {
    return modules.Script{
        .name = "AudioSource",
        .strategy = &self._script_strategy,
    };
}

pub fn play(self: *AudioSource) void {
    self._track.?.play();
}

/// 1.0 volume is equivalent to 100%.
pub fn setVolume(self: *AudioSource, volume: f32) void {
    self._volume = volume;
}

fn start(s: *modules.Script, _: *modules.Object) void {
    const self = @as(
        *AudioSource,
        @constCast(@fieldParentPtr("_script_strategy", s.strategy)),
    );
    if (self.autoplay) self.play();
}

fn update(_: *modules.Script, _: *modules.Object, _: f32) void {
    // const self = @as(
    //     *AudioSource,
    //     @constCast(@fieldParentPtr("_script_strategy", s.strategy)),
    // );

    // Get the target (any object with audio listener)
    // Calculate the distance between the carrier object and the target
    // Calculate audio attenuation using the distance `A(d)`
    // Calculate the angle between the carrier object and the target
    // Calculate Pl (left panning coefficient) and Pr (right panning coefficient)
    // Calculate Gl (left-channel gain) and Gr (right-channel gain)
}

fn end(_: *modules.Script, _: *modules.Object) void {}
