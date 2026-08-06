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

    // Define Rect Drawable
    var rect = zest.drawables.Rect.new(
        .{ .w = 20, .h = 20, .d = 1 },
        .{ .g = 255 },
    );
    var rect_drawable = rect.toDrawable();

    // Define movement script
    var movement = try zest.scripts.Movement.init(allocator, 5, true);
    defer movement.deinit();

    // Create the Object
    var obj = zest.modules.Object.init(allocator, .{
        .name = "GreenBox",
        .position = .{ .x = 20, .y = 20, .z = 1 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &rect_drawable,
    });
    defer obj.deinit();
    try obj.addScript(movement.toScript());

    // Add a child object to obj
    var rect2 = zest.drawables.Rect.new(
        .{ .w = 10, .h = 10, .d = 1 },
        .{ .r = 255 },
    );
    var rect2_drawable = rect2.toDrawable();
    var obj2 = zest.modules.Object.init(allocator, .{
        .name = "RedBox",
        .position = .{ .x = 5, .y = 5, .z = 0 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &rect2_drawable,
    });
    defer obj2.deinit();
    try obj.addChild(&obj2);

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
