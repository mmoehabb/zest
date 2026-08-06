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

    // Create sprite object
    var idle = zest.drawables.Sprite.new(.{
        .img_path = "./examples/assets/anim_explosion.png",
        .frames_count = 0,
        .frame_width = 128,
        .frame_height = 140,
    });
    var idle_drawable = idle.toDrawable(.{ .w = 120, .h = 150, .d = 1 }, .{});

    var audioPlayer = try zest.scripts.AudioPlayer.init(
        allocator,
        "./examples/assets/explosion.wav",
        false,
    );
    defer audioPlayer.deinit();

    var obj = zest.modules.Object.init(allocator, .{
        .position = .{ .x = 100, .y = 20, .z = 1 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &idle_drawable,
    });
    defer obj.deinit();
    try obj.addScript(audioPlayer.toScript());

    // Create text object
    var text = zest.drawables.GUI.Text.new(.{
        .text = "Press Space",
        .font_path = "./examples/assets/OpenSans-Regular.ttf",
        .font_size = 24,
    });
    var text_drawable = text.toDrawable();

    var obj2 = zest.modules.Object.init(allocator, .{
        .position = .{ .x = 90, .y = 170, .z = 1 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &text_drawable,
    });
    defer obj2.deinit();

    // Extend the update function in the obj so that
    // the drawable changes to explode and the audio plays
    // once the user presses space
    obj.lifecycle.postUpdate = struct {
        var explode = zest.drawables.Sprite.new(.{
            .img_path = "./examples/assets/anim_explosion.png",
            .frames_count = 7,
            .frame_width = 128,
            .frame_height = 140,
        });
        var explode_drawable = explode.toDrawable(.{ .w = 120, .h = 150, .d = 1 }, .{});

        var pressed = false;
        var em: ?*zest.plugins.EventManager = null;

        fn func(self: *anyopaque) void {
            const o = @as(*zest.modules.Object, @ptrCast(@alignCast(self)));
            em = em orelse zest.modules.PluginManager.get(zest.plugins.EventManager, "EventManager").?;
            var ap = o.getScript(zest.scripts.AudioPlayer, "AudioPlayer");

            if (em.?.isKeyDown(.Space) and !pressed) {
                _ = ap.?.play() catch unreachable;
                o.setDrawable(&explode_drawable);
                pressed = true;
            }
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
        .width = 320,
        .height = 320,
        .rate = 1000 / 60,
    });
    defer screen.deinit();
    screen.setScene(&scene);
    try screen.open();
}
