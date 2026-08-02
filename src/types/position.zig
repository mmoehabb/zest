// TODO: improve the performance of these methods by using zig vectors (SIMD).

const std = @import("std");
const Position = @This();

x: f32 = 0,
y: f32 = 0,
z: f32 = 0,

pub fn add(self: Position, pos: Position) Position {
    return .{
        .x = self.x + pos.x,
        .y = self.y + pos.y,
        .z = self.z + pos.z,
    };
}

pub fn subtract(self: Position, pos: Position) Position {
    return .{
        .x = self.x - pos.x,
        .y = self.y - pos.y,
        .z = self.z - pos.z,
    };
}

pub fn multiply(self: Position, operand: f32) Position {
    return .{
        .x = self.x * operand,
        .y = self.y * operand,
        .z = self.z * operand,
    };
}

pub fn dot(self: Position, p: Position) Position {
    return .{
        .x = self.x * p.x,
        .y = self.y * p.y,
        .z = self.z * p.z,
    };
}

pub fn magnitude(self: Position) f32 {
    const x = std.math.pow(f32, self.x, 2);
    const y = std.math.pow(f32, self.y, 2);
    const z = std.math.pow(f32, self.z, 2);
    return @sqrt(x + y + z);
}

pub fn abs(self: Position) Position {
    return .{
        .x = @abs(self.x),
        .y = @abs(self.y),
        .z = @abs(self.z),
    };
}

pub fn divide(self: Position, p: Position) Position {
    return .{
        .x = if (p.x > 0) self.x / p.x else 0,
        .y = if (p.y > 0) self.y / p.y else 0,
        .z = if (p.z > 0) self.z / p.z else 0,
    };
}

pub fn isEql(self: Position, p: Position) bool {
    return self.x == p.x and self.y == p.y and self.z == p.z;
}
