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

minD: f32 = 100.0,
maxD: f32 = 1000.0,

_volume: f32 = 1.0,
_track: ?*modules.AudioTrack = null,

_script_strategy: modules.ScriptStrategy = modules.ScriptStrategy{
    .start = start,
    .update = update,
    .end = end,
},

_allocator: std.mem.Allocator,
_manager: *plugins.AudioManager,

pub fn init(allocator: std.mem.Allocator, config: struct {
    path: []const u8 = "",
    loop: bool = false,
    autoplay: bool = false,
    minD: f32 = 100.0,
    maxD: f32 = 1000.0,
}) !*AudioSource {
    const audioManager = modules.PluginManager.get(
        plugins.AudioManager,
        "AudioManager",
    );
    if (audioManager) |manager| {
        var audioSource = try allocator.create(AudioSource);
        audioSource.path = config.path;
        audioSource.loop = config.loop;
        audioSource.autoplay = config.autoplay;
        audioSource.minD = config.minD;
        audioSource.maxD = config.maxD;
        audioSource._volume = 1.0;
        audioSource._track = try manager.newTrack(config.path);
        audioSource._script_strategy = .{
            .start = start,
            .update = update,
            .end = end,
        };
        audioSource._allocator = allocator;
        audioSource._manager = manager;
        return audioSource;
    } else {
        std.log.err("[SCRIPT] AudioListener: You must add AudioManager plugin.", .{});
        return error.PluginNotFound;
    }
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

fn update(s: *modules.Script, obj: *modules.Object, _: f32) void {
    const self = @as(
        *AudioSource,
        @constCast(@fieldParentPtr("_script_strategy", s.strategy)),
    );

    if (self._track) |track| {
        var gl: f32 = 0.00;
        var gr: f32 = 0.00;
        const n: f32 = @as(f32, @floatFromInt(self._manager._audio_listeners.items.len));
        if (n <= 0.00) return;

        for (self._manager._audio_listeners.items) |target| {
            // Calculate the distance between the carrier object and the target
            const d = obj.position.subtract(target.position).magnitude();

            // Calculate audio attenuation using the distance `A(d)`
            const atten = 1.0 - std.math.clamp((d - self.minD) / (self.maxD - self.minD), 0.0, 1.0);

            // Calculate the angle of the vector from the carrier position to the target position.
            const v = target.position.subtract(obj.position);
            const v_mag = v.magnitude();
            const p = if (v_mag > 0.00) v.x / v_mag else 0.00;

            // Calculate Pl (left panning coefficient) and Pr (right panning coefficient)
            const ang = ((p + 1.0) / 4.0) * std.math.pi;
            const pl = @sin(ang);
            const pr = @cos(ang);

            // Calculate Gl (left-channel gain) and Gr (right-channel gain)
            gl += @abs(self._volume * atten * pl);
            gr += @abs(self._volume * atten * pr);
        }

        _ = track.setGains(gl / n, gr / n);
    }
}

fn end(_: *modules.Script, _: *modules.Object) void {}
