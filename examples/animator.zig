const zest = @import("zest");
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

    // Define and add plugins
    var eventManager = zest.plugins.EventManager.init(allocator);
    defer eventManager.deinit();

    try zest.modules.PluginManager.init(allocator);
    try zest.modules.PluginManager.add(&eventManager, @typeName(@TypeOf(eventManager)));
    defer zest.modules.PluginManager.deinit();

    // Define Rect Drawable
    var rect = zest.drawables.Rect.new(
        .{ .w = 20, .h = 20, .d = 1 },
        .{ .g = 255 },
    );
    var rect_drawable = rect.toDrawable();

    var animator = try zest.scripts.Animator.init(allocator, .{});
    defer animator.deinit();

    // Create the Object
    var obj = zest.modules.Object.init(allocator, .{
        .name = "GreenBox",
        .position = .{ .x = 20, .y = 20, .z = 1 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &rect_drawable,
    });
    defer obj.deinit();
    try obj.addScript(animator.toScript());

    obj.lifecycle.postOpen = struct {
        fn func(self: *anyopaque) void {
            const o = @as(*zest.modules.Object, @ptrCast(@alignCast(self)));
            const sliding_anim = zest.scripts.Animation.init(o._allocator, &[_]zest.scripts.Animator.Keyframe{}) catch unreachable;
            defer sliding_anim.deinit();
            if (o.getScript(zest.scripts.Animator)) |anim| {
                anim.play(sliding_anim) catch unreachable;
            }
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
