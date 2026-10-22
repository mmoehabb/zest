//! High-level audio manager that can be used to generate audio-streams.
//! It's internally built on top of SDL_MIX library.

const std = @import("std");
const sdl = @import("sdl");
const AudioStream = @import("../modules/audio-stream.zig");
const AudioTrack = @import("../modules/audio-track.zig");

const AudioManager = @This();

_io: std.Io,
_io_thread: ?std.Thread = null,
_allocator: std.mem.Allocator,
_deinitialized: bool = false,

/// The audio streams retrieved from SDL_OpenAudioDeviceStream.
_audio_streams: std.ArrayList(*AudioStream) = std.ArrayList(*AudioStream).empty,
_audio_tracks: std.ArrayList(*AudioTrack) = std.ArrayList(*AudioTrack).empty,
_mixer: ?*sdl.MIX_Mixer,

pub fn init(allocator: std.mem.Allocator, io: std.Io) !AudioManager {
    if (!sdl.MIX_Init()) {
        sdl.SDL_Log("Unable to initialize MIX: %s", sdl.SDL_GetError());
        return error.AudioManagerInitFailed;
    }
    var mixer: ?*sdl.MIX_Mixer = null;
    if (sdl.MIX_CreateMixerDevice(sdl.SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, null)) |m| {
        mixer = m;
    } else {
        sdl.SDL_Log("[PLUGIN] AudioManager: %s", sdl.SDL_GetError());
        return error.AudioManagerInitFailed;
    }
    return AudioManager{
        ._io = io,
        ._allocator = allocator,
        ._audio_streams = std.ArrayList(*AudioStream).empty,
        ._audio_tracks = std.ArrayList(*AudioTrack).empty,
        ._mixer = mixer,
    };
}

pub fn deinit(self: *AudioManager) void {
    self._deinitialized = true;

    if (self._io_thread) |thread| thread.join();
    // if (self._mixer) |m| sdl.MIX_DestroyMixer(m); // For some reason this fails

    for (self._audio_streams.items) |stream| stream.deinit(self._allocator);
    self._audio_streams.deinit(self._allocator);

    for (self._audio_tracks.items) |track| track.deinit(self._allocator);
    self._audio_tracks.deinit(self._allocator);
}

/// This creates a new (paused, by default) audio stream and return it for the user to use.
/// This stream will be auto destroyed soon, by the clean cycle, if it's found empty and not paused.
pub fn newStream(self: *AudioManager, audio_spec: *sdl.SDL_AudioSpec) !*AudioStream {
    const audioStream = try AudioStream.init(self._allocator, audio_spec);
    if (self._audio_streams.items.len == 0 and self._audio_tracks.items.len == 0) {
        self._io_thread = std.Thread.spawn(.{}, invokeCleanCycle, .{self}) catch |e| return e;
    }
    try self._audio_streams.append(self._allocator, audioStream);
    return audioStream;
}

/// This creates a new audio-track based one SDL MIX_Track.
/// This track will be auto destroyed once the audio (loaded from the path) is done playing.
pub fn newTrack(self: *AudioManager, path: []const u8) !*AudioTrack {
    if (sdl.MIX_LoadAudio(self._mixer.?, path.ptr, false)) |audio| {
        if (sdl.MIX_CreateTrack(self._mixer)) |t| {
            var audioTrack = try AudioTrack.init(self._allocator, t);
            try audioTrack.putAudio(audio);

            if (self._audio_streams.items.len == 0 and self._audio_tracks.items.len == 0) {
                self._io_thread = std.Thread.spawn(.{}, invokeCleanCycle, .{self}) catch |e| return e;
            }
            try self._audio_tracks.append(self._allocator, audioTrack);

            return audioTrack;
        }
    }
    return error.NewTrackFailed;
}

fn invokeCleanCycle(self: *AudioManager) void {
    var f = self._io.async(cleanCycle, .{self});
    f.await(self._io);
    if (!self._deinitialized) return self.invokeCleanCycle();
}

/// Loop over the current audio streams/tracks and destroy the unused ones;
/// the ones with no audio data avaiable nor paused.
fn cleanCycle(self: *AudioManager) void {
    self._io.sleep(.fromSeconds(1), .awake) catch {
        std.log.err("audio-player: Io Sleep Failed!", .{});
        for (self._audio_streams.items) |stream| stream.deinit(self._allocator);
        for (self._audio_streams.items, 0..) |_, i| _ = self._audio_streams.orderedRemove(i);
        for (self._audio_tracks.items) |track| track.deinit(self._allocator);
        for (self._audio_tracks.items, 0..) |_, i| _ = self._audio_tracks.orderedRemove(i);
        return;
    };
    if (self._deinitialized) return;

    var indexes: [100]usize = undefined; // TODO: audit
    var cursor: usize = 0;
    for (self._audio_streams.items, 0..) |stream, i| {
        if (stream.isPaused()) continue;
        if (stream.isPlayingAudio()) continue;
        stream.deinit(self._allocator);
        indexes[cursor] = i;
        cursor += 1;
    }
    self._audio_streams.orderedRemoveMany(indexes[0..cursor]);

    cursor = 0;
    for (self._audio_tracks.items, 0..) |track, i| {
        if (track.isPaused()) continue;
        if (track.isPlayingAudio()) continue;
        track.deinit(self._allocator);
        indexes[cursor] = i;
        cursor += 1;
    }
    self._audio_tracks.orderedRemoveMany(indexes[0..cursor]);
}
