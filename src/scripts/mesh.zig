//! Bestow objects with physical properties by specifying its mesh
//! structure. Add this to objects in order to detect collisions.

const std = @import("std");

const modules = @import("../modules/mod.zig");
const types = @import("../types/mod.zig");

const Mesh = @This();

/// The points that aligns the structure of the object mesh.
/// NOTE: It's relative to the objects position.
faces: []types.Face,

_script_strategy: modules.ScriptStrategy = modules.ScriptStrategy{
    .start = start,
    .update = update,
    .end = end,
},

pub fn toScript(self: *Mesh) modules.Script {
    return modules.Script{
        .name = "Mesh",
        .strategy = &self._script_strategy,
    };
}

fn start(_: *modules.Script, obj: *modules.Object) void {
    modules.Globals.getAll().phyzxEngine.addObject(obj) catch std.debug.print(
        "Mesh: couldn't add object into the physics engine!",
        .{},
    );
}

fn update(_: *modules.Script, _: *modules.Object) void {}

fn end(_: *modules.Script, obj: *modules.Object) void {
    modules.Globals.getAll().phyzxEngine.rmvObject(obj);
}
