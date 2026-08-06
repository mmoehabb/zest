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

    const screen_width = 320;
    const screen_height = 320;

    // Create a drawable object
    var text = zest.drawables.GUI.Text.new(.{
        .text = "Hello World!",
        .font_path = "./examples/assets/OpenSans-Regular.ttf",
        .font_size = 24,
    });
    var text_drawable = text.toDrawable();

    var obj = zest.modules.Object.init(allocator, .{
        .position = .{ .x = 20, .y = 20, .z = 1 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &text_drawable,
    });
    defer obj.deinit();

    // Center the drawable object in the screen
    obj.lifecycle.postUpdate = struct {
        fn func(self: *anyopaque) void {
            const o = @as(*zest.modules.Object, @ptrCast(@alignCast(self)));
            const dim = o.drawable.?.dim;
            o.position.x = (screen_width - dim.w) / 2;
            o.position.y = (screen_height - dim.h) / 2;
        }
    }.func;

    // Create a scene and add the obj into it
    var scene = zest.modules.Scene.init(allocator);
    defer scene.deinit();
    try scene.addObject(&obj);

    // Create a screen, attach the scene to it, and open it
    var screen = try zest.modules.Screen.init(.{
        .title = "Simple Game",
        .width = 320,
        .height = 320,
        .rate = 1000 / 60,
    });
    defer screen.deinit();
    screen.setScene(&scene);
    try screen.open();
}
