//! A plugin to prevent/resolve jamming rigidbodies, by ensuring zero
//! jamming before drawing the scene.
//! NOTE: It depends on the collision-detector plugin.
//!
//! You shall embed it in the lifecycle of the scene "postUpdate":
//! ```
//! var scene = zigsdl.modules.Scene.init(allocator);
//! defer scene.deinit();
//!
//! scene.lifecycle.postUpdate = struct {
//!     var jr: ?*zigsdl.plugins.JammingResolver = null;
//!     fn func(_: *anyopaque) void {
//!         jr = jr orelse zigsdl.modules.PluginManager.get(zigsdl.plugins.JammingResolver, "JammingResolver").?;
//!         jr.?.resolve();
//!     }
//! }.func;
//! ```

const std = @import("std");
const PluginManager = @import("../modules/plugin-manager.zig");
const CollisionDetector = @import("./collision-detector.zig");
const Object = @import("../modules/object.zig");
const Collision = @import("../types/collision.zig");

const JammingResolver = @This();

/// A list of subscribed objects to prevent jamming amongst.
_objects: std.ArrayList(*Object) = .empty,

_collisionDetector: *CollisionDetector,
_allocator: std.mem.Allocator,

/// Just a buffer for the resolve method to use.
_collisions: std.ArrayList(Collision) = .empty,

pub fn init(allocator: std.mem.Allocator) !JammingResolver {
    if (PluginManager.isInitialized() == false) return error.PluginManagerRequired;
    if (PluginManager.get(CollisionDetector, "CollisionDetector")) |cd| {
        return .{
            ._collisionDetector = cd,
            ._allocator = allocator,
        };
    }
    return error.CollisionDetectorPluginRequired;
}

pub fn deinit(self: *JammingResolver) void {
    self._objects.deinit(self._allocator);
    self._collisions.deinit(self._allocator);
}

pub fn resolve(self: *JammingResolver) void {
    const dc = self._collisionDetector;
    dc.detectCollision(); // Ensure that the collision detector has the latest state

    for (self._objects.items) |obj| {
        self._collisions.clearRetainingCapacity();
        dc.getCollisions(obj, self._allocator, &self._collisions) catch {
            std.log.err("JammingResolver.resolve: collisions couldn't be resolved!", .{});
            return;
        };

        // Resolve rigibodies jamming using the `collision`s structs
        for (self._collisions.items) |c| {
            obj.position.y += c.y;
        }
    }
}

/// Add object to the collection in which jamming shall be resolved.
pub fn addObject(self: *JammingResolver, obj: *Object) !void {
    try self._objects.append(self._allocator, obj);
}

/// Remove object from the collection in which the jamming shall be resolved.
pub fn rmvObject(self: *JammingResolver, obj: *Object) void {
    var index: ?usize = null;
    for (self._objects.items, 0..) |o, i| {
        if (o == obj) {
            index = i;
            break;
        }
    }
    if (index) |i| _ = self._objects.orderedRemove(i);
}
