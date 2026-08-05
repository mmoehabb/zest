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

const JammingResolver = @This();

_collisionDetector: *CollisionDetector,

pub fn init() !JammingResolver {
    if (PluginManager.isInitialized() == false) return error.PluginManagerRequired;
    if (PluginManager.get(CollisionDetector, "CollisionDetector")) |cd| {
        return .{ ._collisionDetector = cd };
    }
    return error.CollisionDetectorPluginRequired;
}

pub fn resolve(self: *JammingResolver) void {
    _ = self._collisionDetector;
}
