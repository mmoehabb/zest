//! A concrete drawable that renders texts by using sdl_ttf.

const std = @import("std");
const sdl = @import("sdl");
const modules = @import("../../modules/mod.zig");
const types = @import("../../types/mod.zig");

const Text = @This();

text: []const u8,
font_path: []const u8,
font_size: f32,
color: types.Color = .{ .b = 255, .g = 255, .r = 255 },

_texture: ?[*c]sdl.SDL_Texture = null,
_draw_strategy: modules.DrawStrategy = .{
    .draw = draw,
    .destroy = destroy,
},

pub fn new(t: Text) Text {
    return Text{
        .text = t.text,
        .font_path = t.font_path,
        .font_size = t.font_size,
        .color = .{ .r = 255, .g = 255, .b = 255 },
    };
}

pub fn toDrawable(self: *Text) modules.Drawable {
    return modules.Drawable{
        .dim = .{ .w = 0, .h = 0, .d = 0 },
        .color = self.color,
        .drawStrategy = &self._draw_strategy,
    };
}

pub fn getDim(self: *Text) types.Dimensions {
    return .{
        .w = if (self._texture) |t| @floatFromInt(t.*.w) else 0,
        .h = if (self._texture) |t| @floatFromInt(t.*.h) else 0,
        .d = 1,
    };
}

pub fn setLabel(self: *Text, label: []const u8) void {
    self.text = label;
    self._texture = null;
}

fn draw(
    drawable: *modules.Drawable,
    ds: *const modules.DrawStrategy,
    renderer: *sdl.SDL_Renderer,
    pos: types.Vector,
    rot: types.Vector,
    _: types.Dimensions,
) !void {
    const self = @as(*Text, @constCast(@fieldParentPtr("_draw_strategy", ds)));

    const texture = self._texture orelse blk: {
        const font = sdl.TTF_OpenFont(self.font_path.ptr, self.font_size);
        const text = if (self.text.len > 0) self.text else " ";
        const surface = sdl.TTF_RenderText_Blended(font, text.ptr, text.len, sdl.SDL_Color{
            .a = self.*.color.a,
            .b = self.*.color.b,
            .g = self.*.color.g,
            .r = self.*.color.r,
        });
        defer sdl.SDL_DestroySurface(surface);
        const texture = sdl.SDL_CreateTextureFromSurface(renderer, surface);
        _ = sdl.SDL_SetTextureScaleMode(texture, sdl.SDL_SCALEMODE_LINEAR);
        break :blk texture;
    };

    const dest = sdl.SDL_FRect{
        .x = pos.x,
        .y = pos.y,
        .w = @as(f32, @floatFromInt(texture.*.w)),
        .h = @as(f32, @floatFromInt(texture.*.h)),
    };

    const center = sdl.SDL_FPoint{
        .x = dest.w / 2,
        .y = dest.h / 2,
    };

    const flip: c_uint = blk: {
        if (rot.x > 0) break :blk sdl.SDL_FLIP_VERTICAL;
        if (rot.y > 0) break :blk sdl.SDL_FLIP_HORIZONTAL;
        break :blk sdl.SDL_FLIP_NONE;
    };

    if (!sdl.SDL_RenderTextureRotated(
        renderer,
        texture,
        null,
        &dest,
        rot.z,
        &center,
        flip,
    )) return error.RenderFailed;

    drawable.setDim(.{
        .w = @as(f32, @floatFromInt(texture.*.w)),
        .h = @as(f32, @floatFromInt(texture.*.h)),
        .d = 1,
    });
}

fn destroy(_: *modules.Drawable, ds: *const modules.DrawStrategy) void {
    const self = @as(*Text, @constCast(@fieldParentPtr("_draw_strategy", ds)));
    if (self._texture) |t| sdl.SDL_DestroyTexture(t);
}
