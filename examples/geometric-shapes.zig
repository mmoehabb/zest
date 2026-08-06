const zest = @import("zest");
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

    // Define and add plugins
    var eventManager = zest.plugins.EventManager.init(allocator);
    defer eventManager.deinit();
    var stringFactory = try zest.plugins.StringFactory.init(allocator);
    defer stringFactory.deinit();

    try zest.modules.PluginManager.init(allocator);
    try zest.modules.PluginManager.add(&eventManager, "EventManager");
    try zest.modules.PluginManager.add(&stringFactory, "StringFactory");
    defer zest.modules.PluginManager.deinit();

    // A Green Rectangle
    var rect = zest.drawables.Rect.new(
        .{ .w = 50, .h = 25, .d = 1 },
        .{ .g = 255 },
    );
    var rect_drawable = rect.toDrawable();

    var obj1 = zest.modules.Object.init(allocator, .{
        .name = "GreenRect",
        .position = .{ .x = 20, .y = 20, .z = 1 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &rect_drawable,
    });
    defer obj1.deinit();

    // A Red Square
    var square = zest.drawables.Rect.new(
        .{ .w = 50, .h = 50, .d = 1 },
        .{ .r = 255 },
    );
    var square_drawable = square.toDrawable();
    var obj2 = zest.modules.Object.init(allocator, .{
        .name = "RedSquare",
        .position = .{ .x = 20, .y = 65, .z = 1 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &square_drawable,
    });
    defer obj2.deinit();

    // Add Blue Circle
    var circle = try zest.drawables.Ellipse.new(
        init.io,
        .{ .w = 25, .h = 25, .d = 1 },
        .{ .b = 255 },
    );
    var circle_drawable = circle.toDrawable();
    var obj3 = zest.modules.Object.init(allocator, .{
        .name = "BlueCircle",
        .position = .{ .x = 20, .y = 135, .z = 1 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &circle_drawable,
    });
    defer obj3.deinit();

    // Add Yellow Triangle
    var triangle = zest.drawables.Triangle.new(
        .{ .w = 50, .h = 50, .d = 1 },
        .{ .r = 255, .g = 255 },
    );
    var triangle_drawable = triangle.toDrawable();
    var obj4 = zest.modules.Object.init(allocator, .{
        .name = "YellowTriangle",
        .position = .{ .x = 20, .y = 205, .z = 1 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &triangle_drawable,
    });
    defer obj4.deinit();

    // Create a scene and add the obj into it
    var scene = zest.modules.Scene.init(allocator);
    defer scene.deinit();

    try scene.addObject(&obj1);
    try scene.addObject(&obj2);
    try scene.addObject(&obj3);
    try scene.addObject(&obj4);

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
