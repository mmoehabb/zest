//! A concrete drawable to render a simple eclipse by using the power of SVG.
//! NOTE: this is a simple wrapper on the SVG component.

const std = @import("std");
const sdl = @import("sdl");
const modules = @import("../modules/mod.zig");
const plugins = @import("../plugins/mod.zig");
const types = @import("../types/mod.zig");
const SVG = @import("./svg.zig");

const Ellipse = @This();

dim: types.Dimensions,
color: types.Color = .{},

// NOTE: the dimention width is used for the first radius (r1 = 2*w), and the height for the second.
pub fn new(io: std.Io, dim: types.Dimensions, _: types.Color) !SVG {
    if (modules.PluginManager.isInitialized() == false) {
        std.log.err("Eclipse.new: you must initialize the PluginManager first.", .{});
        return error.PluginManagerRequired;
    }

    const stringFactory = modules.PluginManager.get(plugins.StringFactory, "StringFactory");
    if (stringFactory) |sf| {
        const format =
            \\<svg width="{0}" height="{1}" xmlns="http://www.w3.org/2000/svg">
            \\<ellipse cx="{2}" cy="{3}" rx="{2}" ry="{3}" fill="red" />
            \\</svg>
        ;
        var str = try sf.createBuffer(512);

        const svg_content = std.fmt.bufPrint(
            str.getBuffer(),
            format,
            .{
                dim.w * 2,
                dim.h * 2,
                dim.w,
                dim.h,
            },
        ) catch "<svg></svg>";

        return SVG.new(SVG{
            .io = io,
            .content = svg_content,
            .dim = dim,
        });
    }

    std.log.err("Eclipse.new: StringFactory plugin is required!", .{});
    return error.StringFactoryRequired;
}
