//! Add this script to any object in order to add physical properties to it;
//! detect collisions, mass, and gravity.

const std = @import("std");
const modules = @import("../modules/mod.zig");
const types = @import("../types/mod.zig");

const Rigidbody = @This();

mass: f32,
gravity: bool,

_landed: bool = false,
_G: f32 = 0.00,

_script_strategy: modules.ScriptStrategy = modules.ScriptStrategy{
    .start = start,
    .update = update,
    .end = end,
},

_phyzxEngine: ?*modules.PhyzxEngine = null,

pub fn toScript(self: *Rigidbody) modules.Script {
    return modules.Script{
        .name = "Rigidbody",
        .strategy = &self._script_strategy,
    };
}

fn start(s: *modules.Script, _: *modules.Object) void {
    const self = @as(*Rigidbody, @constCast(
        @fieldParentPtr("_script_strategy", s.strategy),
    ));
    self._phyzxEngine = modules.Globals.getAll().phyzxEngine;
}

fn update(s: *modules.Script, obj: *modules.Object) void {
    const self = @as(*Rigidbody, @constCast(
        @fieldParentPtr("_script_strategy", s.strategy),
    ));

    var collisions = [_]?*modules.Object{null} ** 16;
    self._phyzxEngine.?.getCollisions(obj, &collisions) catch unreachable;
    for (collisions) |c| {
        if (c) |_| {
            self._landed = true; // TODO
        } else break;
    }

    if (self._landed) {
        self._G = 0.00;
        return;
    }
    if (self.gravity == false) return;
    obj.position.y += self.mass * self._G;
    self._G += 0.01;
}

fn end(_: *modules.Script, _: *modules.Object) void {}
