const zest = @import("zest");
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

    // Define and add plugins
    var eventManager = zest.plugins.EventManager.init(allocator);
    defer eventManager.deinit();

    try zest.modules.PluginManager.init(allocator);
    try zest.modules.PluginManager.add(&eventManager, "EventManager");
    defer zest.modules.PluginManager.deinit();

    const screen_width = 1024;
    const screen_height = 680;

    // Create a drawable svg object (1)
    var svg = zest.drawables.Svg.new(.{
        .io = init.io,
        .dim = .{ .scale = 0.75 },
        .path = "./examples/assets/lime.svg",
    });
    var svg_drawable = svg.toDrawable();

    var obj = zest.modules.Object.init(allocator, .{
        .position = .{ .x = 0, .y = 0, .z = 1 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &svg_drawable,
    });
    defer obj.deinit();

    // Create a drawable svg object (2)
    var svg2 = zest.drawables.Svg.new(.{
        .io = init.io,
        .content =
        \\ <svg width="100" height="100">
        \\   <circle cx="50" cy="50" r="40" stroke="black" stroke-width="3" fill="red" />
        \\ </svg>
        ,
    });
    var svg2_drawable = svg2.toDrawable();

    var obj2 = zest.modules.Object.init(allocator, .{
        .position = .{ .x = 20, .y = 20, .z = 1 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &svg2_drawable,
    });
    defer obj2.deinit();

    // Center the drawable object in the screen
    obj.lifecycle.postUpdate = struct {
        fn func(self: *anyopaque) void {
            const o = @as(*zest.modules.Object, @ptrCast(@alignCast(self)));
            const dim = o.drawable.?.dim.getScaled();
            o.position.x = (screen_width - dim.w) / 2 / dim.scale;
            o.position.y = (screen_height - dim.h) / 2 / dim.scale;
        }
    }.func;

    // Create a scene and add the obj into it
    var scene = zest.modules.Scene.init(allocator);
    defer scene.deinit();
    try scene.addObject(&obj);
    try scene.addObject(&obj2);

    // Create a screen, attach the scene to it, and open it
    var screen = try zest.modules.Screen.init(.{
        .title = "Simple Game",
        .width = screen_width,
        .height = screen_height,
        .rate = 1000 / 60,
    });
    defer screen.deinit();
    screen.setScene(&scene);
    try screen.open();
}
