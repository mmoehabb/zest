//! A `Collision` struct defines a collision happened between object and an
//! arbitrary face in the space. It gets detected in the CollisionDetector.

const Face = @import("./face.zig");
const Point = @import("./point.zig");

const Collision = @This();

/// The face that the object collides with.
face: Face,

/// The objects face that collides with `.face`.
myface: Face,

/// Collision Point: a struct of the point where collision happened,
/// associated with collision magnitude values.
points: [4]?Point = @splat(null),
_len: u3 = 0,

pub fn addPoint(self: *Collision, p: Point) void {
    if (self._len >= 4) return;
    self.points[self._len] = p;
    self._len += 1;
}
