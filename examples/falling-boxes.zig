const zigsdl = @import("zigsdl");
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

    try zigsdl.modules.Globals.init(allocator, init.io);
    defer zigsdl.modules.Globals.deinit();

    var rect = zigsdl.drawables.Rect.new(
        .{ .w = 20, .h = 20, .d = 1 },
        .{ .r = 255 },
    );
    var box_drawable = rect.toDrawable();

    var boxes: [5]?*Box = @splat(null);

    const rng_impl: std.Random.IoSource = .{ .io = init.io };
    const rng = rng_impl.interface();

    for (0..boxes.len) |i| {
        const rand1 = rng.float(f32);
        const rand2 = rng.float(f32);
        boxes[i] = try Box.init(
            allocator,
            &box_drawable,
            "Box",
            .{
                .x = 300.0 * rand1,
                .y = 200.0 * rand2,
            },
        );
    }
    defer for (&boxes) |*box| if (box.*) |b| b.deinit();

    var terrain_rect = zigsdl.drawables.Rect.new(
        .{ .w = 320, .h = 50, .d = 1 },
        .{ .g = 255 },
    );
    var terrain_drawable = terrain_rect.toDrawable();
    var terrain = zigsdl.modules.Object.init(allocator, .{
        .name = "Terrain",
        .position = .{ .x = 0, .y = 270 },
        .rotation = .{ .x = 0, .y = 0 },
        .drawable = &terrain_drawable,
    });

    var terrain_faces = [_]zigsdl.types.Face{
        .{
            .p1 = .{ .x = 0, .y = 0 },
            .p2 = .{ .x = 320, .y = 0 },
            .p3 = .{ .x = 320, .y = 50 },
            .p4 = .{ .x = 0, .y = 50 },
            .owner = &terrain,
        },
    };
    var terrain_mesh = try zigsdl.scripts.Mesh.init(allocator, &terrain_faces);
    defer terrain_mesh.deinit();

    var terrain_rigidbody = try zigsdl.scripts.Rigidbody.init(.{
        .allocator = allocator,
        .mass = 500,
        .static = true,
    });
    defer terrain_rigidbody.deinit();

    try terrain.addScript(terrain_mesh.toScript());
    try terrain.addScript(terrain_rigidbody.toScript());
    defer terrain.deinit();

    // Create a scene and add the obj into it
    var scene = zigsdl.modules.Scene.init(allocator);
    defer scene.deinit();
    for (boxes) |box| {
        try scene.addObject(box.?.toObject());
    }
    try scene.addObject(&terrain);

    // Create a screen, attach the scene to it, and open it
    var screen = try zigsdl.modules.Screen.init(.{
        .title = "Simple Game",
        .width = 320,
        .height = 320,
        .rate = 1000 / 60,
    });
    defer screen.deinit();
    screen.setScene(&scene);
    try screen.open();
}

const Box = struct {
    _obj: zigsdl.modules.Object,
    _mesh: *zigsdl.scripts.Mesh,
    _rigidbody: *zigsdl.scripts.Rigidbody,
    _allocator: std.mem.Allocator,

    pub fn init(
        allocator: std.mem.Allocator,
        drawable: *zigsdl.modules.Drawable,
        name: []const u8,
        p: zigsdl.types.Position,
    ) !*Box {
        var box = try allocator.create(Box);
        box._allocator = allocator;

        box._obj = zigsdl.modules.Object.init(allocator, .{
            .name = name,
            .position = p,
            .rotation = .{ .x = 0, .y = 0 },
            .drawable = drawable,
        });

        var box_faces = [_]zigsdl.types.Face{
            .{
                .p1 = .{ .x = 0, .y = 0 },
                .p2 = .{ .x = 20, .y = 0 },
                .p3 = .{ .x = 20, .y = 20 },
                .p4 = .{ .x = 0, .y = 20 },
                .owner = &box._obj,
            },
        };
        var box_mesh = try zigsdl.scripts.Mesh.init(allocator, &box_faces);
        try box._obj.addScript(box_mesh.toScript());
        box._mesh = box_mesh;

        var box_rigidbody = try zigsdl.scripts.Rigidbody.init(.{
            .allocator = allocator,
            .mass = 5,
            .gravity = true,
            .static = false,
        });
        try box._obj.addScript(box_rigidbody.toScript());
        box._rigidbody = box_rigidbody;

        return box;
    }

    pub fn deinit(self: *Box) void {
        self._obj.deinit();
        self._mesh.deinit();
        self._rigidbody.deinit();
        self._allocator.destroy(self);
    }

    pub fn toObject(self: *Box) *zigsdl.modules.Object {
        return &self._obj;
    }
};
