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

    // Create a drawable object
    var rect = zest.drawables.Rect.new(
        .{ .w = 550, .h = 70, .d = 1 },
        .{ .g = 255 },
    );
    var rect_drawable = rect.toDrawable();

    var obj = zest.modules.Object.init(allocator, .{
        .name = "Ground",
        .position = .{ .x = -100, .y = 250, .z = 1 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &rect_drawable,
    });
    defer obj.deinit();

    // Add a child object to obj
    var rect2 = zest.drawables.Rect.new(
        .{ .w = 60, .h = 100, .d = 1 },
        .{ .r = 255 },
    );
    var rect2_drawable = rect2.toDrawable();
    var obj2 = zest.modules.Object.init(allocator, .{
        .name = "RedBar",
        .position = .{ .x = 50, .y = 150, .z = 1 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &rect2_drawable,
    });
    defer obj2.deinit();

    // Add a child object to obj
    var rect3 = zest.drawables.Rect.new(
        .{ .w = 60, .h = 100, .d = 1 },
        .{ .b = 255 },
    );
    var rect3_drawable = rect3.toDrawable();
    var obj3 = zest.modules.Object.init(allocator, .{
        .name = "BlueBar",
        .position = .{ .x = 150, .y = 100, .z = 1 },
        .rotation = .{ .z = -45 },
        .drawable = &rect3_drawable,
    });
    defer obj3.deinit();

    // Create a scene and add the obj into it
    var scene = zest.modules.Scene.init(allocator);
    defer scene.deinit();
    try scene.addObject(&obj);
    try scene.addObject(&obj2);
    try scene.addObject(&obj3);

    scene.lifecycle.postUpdate = struct {
        var em: ?*zest.plugins.EventManager = null;
        fn func(self: *anyopaque) void {
            const s = @as(*zest.modules.Scene, @ptrCast(@alignCast(self)));
            em = em orelse zest.modules.PluginManager.get(zest.plugins.EventManager, "EventManager").?;
            if (em.?.isKeyDown(.W)) s.move(.{ .y = 5 });
            if (em.?.isKeyDown(.D)) s.move(.{ .x = -5 });
            if (em.?.isKeyDown(.S)) s.move(.{ .y = -5 });
            if (em.?.isKeyDown(.A)) s.move(.{ .x = 5 });
            if (em.?.isKeyDown(.E)) s.scale += 0.1;
            if (em.?.isKeyDown(.Q)) s.scale -= 0.1;
        }
    }.func;

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
