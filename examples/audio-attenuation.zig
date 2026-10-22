const zest = @import("zest");
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

    // Define and add plugins
    var eventManager = zest.plugins.EventManager.init(allocator);
    defer eventManager.deinit();

    var audioManager = try zest.plugins.AudioManager.init(allocator, init.io);
    defer audioManager.deinit();

    try zest.modules.PluginManager.init(allocator);
    try zest.modules.PluginManager.add(&eventManager, "EventManager");
    try zest.modules.PluginManager.add(&audioManager, "AudioManager");
    defer zest.modules.PluginManager.deinit();

    // Movable Object
    var rect = zest.drawables.Rect.new(
        .{ .w = 20, .h = 20, .d = 1 },
        .{ .g = 255 },
    );
    var rect_drawable = rect.toDrawable();

    var movement = try zest.scripts.Movement.init(allocator, 5, true);
    defer movement.deinit();

    var obj = zest.modules.Object.init(allocator, .{
        .name = "GreenBox",
        .position = .{ .x = 20, .y = 20, .z = 1 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &rect_drawable,
    });
    defer obj.deinit();
    try obj.addScript(movement.toScript());

    // Radio Object
    var yrect = zest.drawables.Rect.new(
        .{ .w = 20, .h = 20, .d = 1 },
        .{ .r = 255, .g = 255 },
    );
    var yrect_drawable = yrect.toDrawable();

    var audio_source = try zest.scripts.AudioSource.init(allocator, .{
        .path = "./examples/assets/bg-music.ogg",
        .loop = true,
        .autoplay = true,
    });
    defer audio_source.deinit();

    var radio_obj = zest.modules.Object.init(allocator, .{
        .name = "Radio",
        .position = .{ .x = 100, .y = 100, .z = 1 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &yrect_drawable,
    });
    defer radio_obj.deinit();
    try radio_obj.addScript(audio_source.toScript());

    // Create a scene and add the obj into it
    var scene = zest.modules.Scene.init(allocator);
    defer scene.deinit();
    try scene.addObject(&obj);
    try scene.addObject(&radio_obj);

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
