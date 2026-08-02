const std = @import("std");
const sdl = @import("sdl");

const AudioStream = @This();

_stream: ?*sdl.SDL_AudioStream = null,

pub fn new(audio_spec: *sdl.SDL_AudioSpec) !AudioStream {
    if (sdl.SDL_OpenAudioDeviceStream(
        sdl.SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK,
        audio_spec,
        null,
        null,
    )) |stream| {
        return AudioStream{
            ._stream = stream,
        };
    } else {
        std.log.err("AudioStream: {s}\n", .{sdl.SDL_GetError()});
        return error.NewStreamFailed;
    }
}

pub fn destroy(self: *const AudioStream) void {
    sdl.SDL_DestroyAudioStream(self._stream);
}

pub fn putAudio(self: *const AudioStream, buf: [*c]u8, len: usize) void {
    if (!sdl.SDL_PutAudioStreamData(
        self._stream,
        buf,
        @as(c_int, @intCast(len)),
    )) {
        std.log.err("AudioStream: {s}\n", .{sdl.SDL_GetError()});
        return;
    }
}

pub fn isPaused(self: *const AudioStream) bool {
    return sdl.SDL_AudioStreamDevicePaused(self._stream);
}

pub fn isPlayingAudio(self: *const AudioStream) bool {
    return sdl.SDL_GetAudioStreamAvailable(self._stream) > 0;
}

pub fn pause(self: *const AudioStream) void {
    if (!sdl.SDL_PauseAudioStreamDevice(self._audio_stream)) {
        std.log.warn("AudioPlayer: {s}", .{sdl.SDL_GetError()});
    }
}

pub fn @"resume"(self: *const AudioStream) void {
    if (!sdl.SDL_ResumeAudioStreamDevice(self._stream)) {
        std.log.warn("AudioPlayer: {s}", .{sdl.SDL_GetError()});
    }
}
