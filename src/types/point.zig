//! Just a simple (x y z) point, with no methods. If you need
//! more capable struct use may use `Vector`.

const std = @import("std");
const Point = @This();

x: f32 = 0,
y: f32 = 0,
z: f32 = 0,
