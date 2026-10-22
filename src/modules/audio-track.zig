//! struct for loading and playing any audio file by using SDL MIX_Track.

const std = @import("std");
const sdl = @import("sdl");

const AudioTrack = @This();

_track: *sdl.MIX_Track,
_audio: ?*sdl.MIX_Audio = null,
_gains: sdl.MIX_StereoGains = sdl.MIX_StereoGains{ .left = 1.0, .right = 1.0 },

pub fn init(allocator: std.mem.Allocator, track: *sdl.MIX_Track) !*AudioTrack {
    var audioTrack = try allocator.create(AudioTrack);
    audioTrack._track = track;
    audioTrack._audio = null;
    audioTrack._gains = sdl.MIX_StereoGains{ .left = 1.0, .right = 1.0 };
    return audioTrack;
}

pub fn deinit(self: *AudioTrack, allocator: std.mem.Allocator) void {
    sdl.MIX_DestroyTrack(self._track);
    if (self._audio) |a| sdl.MIX_DestroyAudio(a);
    allocator.destroy(self);
}

pub fn putAudio(self: *AudioTrack, audio: *sdl.MIX_Audio) !void {
    if (!sdl.MIX_SetTrackAudio(self._track, audio)) {
        std.log.err("[MODULE] AudioTrack: {s}\n", .{sdl.SDL_GetError()});
        return error.PutAudioFailed;
    }
    if (self._audio) |a| sdl.MIX_DestroyAudio(a);
    self._audio = audio;
}

pub fn play(self: *AudioTrack) void {
    if (!sdl.MIX_PlayTrack(self._track, 0)) {
        std.log.warn("[MODULE] AudioTrack: {s}", .{sdl.SDL_GetError()});
    }
}

pub fn pause(self: *AudioTrack) void {
    if (!sdl.MIX_PauseTrack(self._track)) {
        std.log.warn("[MODULE] AudioTrack: {s}", .{sdl.SDL_GetError()});
    }
}

pub fn @"resume"(self: *AudioTrack) void {
    if (!sdl.MIX_ResumeTrack(self._track)) {
        std.log.warn("[MODULE] AudioTrack: {s}", .{sdl.SDL_GetError()});
    }
}

pub fn setGains(self: *AudioTrack, left: f32, right: f32) bool {
    self._gains.left = left;
    self._gains.right = right;
    return sdl.MIX_SetTrackStereo(self._track, &self._gains);
}

pub fn isPaused(self: *AudioTrack) bool {
    return sdl.MIX_TrackPaused(self._track);
}

pub fn isPlayingAudio(self: *AudioTrack) bool {
    return sdl.MIX_TrackPlaying(self._track);
}
