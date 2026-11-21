//! Attach this script into objects in order to play some animations on them.
//! See also: Animation, Keyframe, and Property.

const std = @import("std");
const modules = @import("../modules/mod.zig");
const plugins = @import("../plugins/mod.zig");
const types = @import("../types/mod.zig");

const Animator = @This();

_parent: ?*modules.Object = null,
_anim: ?*Animation = null,
_speed: f32 = 1.00,

_script_strategy: modules.ScriptStrategy = modules.ScriptStrategy{
    .start = start,
    .update = update,
    .end = end,
},

_allocator: std.mem.Allocator,

pub fn init(
    allocator: std.mem.Allocator,
    config: struct {
        parent: ?*modules.Object = null,
        anim: ?*modules.Object = null,
        speed: f32 = 1.00,
    },
) !*Animator {
    var script = try allocator.create(Animator);
    script._script_strategy = .{
        .start = start,
        .update = update,
        .end = end,
    };
    script._allocator = allocator;
    script._parent = config.parent;
    script._speed = config.speed;
    script._anim = null;
    return script;
}

pub fn deinit(self: *Animator) void {
    if (self._anim) |anim| anim.deinit();
    self._allocator.destroy(self);
}

pub fn toScript(self: *Animator) modules.Script {
    return modules.Script{
        .name = @typeName(Animator),
        .strategy = &self._script_strategy,
    };
}

fn start(s: *modules.Script, obj: *modules.Object) void {
    const self = @as(*Animator, @constCast(
        @fieldParentPtr("_script_strategy", s.strategy),
    ));
    self._parent = obj;
}

fn update(s: *modules.Script, _: *modules.Object, _: f32) void {
    const self = @as(*Animator, @constCast(
        @fieldParentPtr("_script_strategy", s.strategy),
    ));
    if (self._anim) |_| {
        std.debug.print("FOUND\n", .{});
    }
}

fn end(_: *modules.Script, _: *modules.Object) void {}

/// This clones the passed animation and deinits it (the clone)
/// with this script deinit, or when replaced by another animation.
pub fn play(self: *Animator, animation: *Animation) !void {
    if (self._anim) |old| old.deinit();
    self._anim = try animation.clone(self._allocator);
}

/// Validate that a specific Animation can be played on the parent Object.
fn validateAnim(_: *Animator, _: Animation) bool {
    return true;
}

// *******************************
// *********** OTHER *************
// *******************************
pub const Animation = struct {
    _keyframes: []Keyframe,
    _allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, keyframes: []Keyframe) !*Animation {
        const anim = try allocator.create(Animation);
        anim._allocator = allocator;
        anim._keyframes = try allocator.dupe(Keyframe, keyframes);
        return anim;
    }

    pub fn deinit(self: *Animation) void {
        self._allocator.free(self._keyframes);
        self._allocator.destroy(self);
    }

    pub fn clone(self: *Animation, allocator: std.mem.Allocator) !*Animation {
        const anim = try allocator.create(Animation);
        anim._allocator = allocator;
        anim._keyframes = try allocator.dupe(Keyframe, self._keyframes);
        return anim;
    }
};

pub const Keyframe = struct {
    properties: []Keypoint,
};

pub const Keypoint = struct {
    /// It acts on the root (object) when script equals an empty string.
    script: []const u8 = "",
    field: []const u8 = "",
    value: *anyopaque = null,
};
