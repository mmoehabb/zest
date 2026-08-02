const std = @import("std");
const Object = @import("../object.zig");
const Mesh = @import("../../scripts/mesh.zig");
const Face = @import("../../types/face.zig");
const Collision = @import("../../types/collision.zig");
const Position = @import("../../types/position.zig");

const PhyzxEngine = @This();

_io: std.Io,
_allocator: std.mem.Allocator,
_thread: ?std.Thread = null,
_deinitializing: bool = false,

/// A list of subscribed object to collision detection cycle.
_objects: std.ArrayList(*Object) = .empty,

_collision_map: std.AutoHashMap(*Object, std.ArrayList(Collision)),

/// All faces available in the space.
/// NOTE: This is used as a buffer, in order to optimize the detection thread
/// execution, by avoiding constantly allocating and deallocating memory.
_faces: std.ArrayList(Face) = .empty,

/// Used before retrieving or manipulating any state (data) used in the detection thread.
_state_mutex: std.Io.Mutex = .init,

pub fn init(allocator: std.mem.Allocator, io: std.Io) PhyzxEngine {
    return PhyzxEngine{
        ._io = io,
        ._allocator = allocator,
        ._collision_map = std.AutoHashMap(
            *Object,
            std.ArrayList(Collision),
        ).init(allocator),
    };
}

pub fn deinit(self: *PhyzxEngine) void {
    self._deinitializing = true;
    if (self._thread) |thread| thread.join();

    var iter = self._collision_map.valueIterator();
    while (iter.next()) |v| v.deinit(self._allocator);
    self._collision_map.deinit();

    self._objects.deinit(self._allocator);
    self._faces.deinit(self._allocator);
}

pub fn start(self: *PhyzxEngine) !void {
    self._thread = try std.Thread.spawn(.{}, detectCollisionThread, .{self});
}

/// Add object to the collection on which the collision detector shall operate.
pub fn addObject(self: *PhyzxEngine, obj: *Object) !void {
    try self._state_mutex.lock(self._io);
    defer self._state_mutex.unlock(self._io);
    try self._objects.append(self._allocator, obj);
}

/// Remove object from the collection on which the collision detector shall operate.
pub fn rmvObject(self: *PhyzxEngine, obj: *Object) void {
    self._state_mutex.lock(self._io) catch unreachable;
    defer self._state_mutex.unlock(self._io);
    var index: ?usize = null;
    for (self._objects.items, 0..) |o, i| {
        if (o == obj) {
            index = i;
            break;
        }
    }
    if (index) |i| _ = self._objects.orderedRemove(i);
}

/// Get a slice of objects that collides with the passed _obj_ parameter, and append
/// them into the passed _arr_.
pub fn getCollisions(self: *PhyzxEngine, obj: *Object, arr: *std.ArrayList(Collision)) !void {
    try self._state_mutex.lock(self._io);
    defer self._state_mutex.unlock(self._io);
    const res = try self._collision_map.getOrPutValue(obj, .empty);
    try arr.appendSlice(self._allocator, res.value_ptr.items);
}

fn detectCollisionThread(self: *PhyzxEngine) void {
    var f = self._io.async(detectCollisionAsync, .{self});
    f.await(self._io);
    if (!self._deinitializing) return self.detectCollisionThread();
}

// TODO: enhance this by invoking it only upon requests; if there is no
// components calling getCollisions, then no need for these computations.
fn detectCollisionAsync(self: *PhyzxEngine) void {
    if (self._deinitializing) return;
    self._io.sleep(.fromMilliseconds(16), .awake) catch {
        std.log.err("phyzx-engine: Io Sleep Failed!", .{});
        return;
    };

    self._state_mutex.lock(self._io) catch unreachable;
    defer self._state_mutex.unlock(self._io);

    // Get all faces available in the space
    for (self._objects.items) |obj| {
        const mesh = obj.getScript(Mesh, "Mesh");
        if (mesh) |m| {
            for (m.faces) |face| {
                // TODO: enhance error handling
                self._faces.append(self._allocator, face) catch unreachable;
            }
        }
    }
    defer self._faces.clearRetainingCapacity();

    // Clear previous collision state
    var iter = self._collision_map.valueIterator();
    while (iter.next()) |e| e.clearRetainingCapacity();

    // Apply the collision detection algorithm for each face
    for (self._faces.items) |A| {
        for (self._faces.items) |B| {
            if (A.owner == B.owner) continue;
            const absA = A.add(A.owner.position);
            const absB = B.add(B.owner.position);

            // TODO: enhance error hanlding
            const cA = self._collision_map.getOrPutValue(A.owner, .empty) catch unreachable;
            const cB = self._collision_map.getOrPutValue(B.owner, .empty) catch unreachable;

            for ([4]Position{ absA.p1, absA.p2, absA.p3, absA.p4 }) |p| {
                // Skip if there is no possible collision
                if (!absB.isPCP(p)) continue;

                const origCircum = absB.calCircum();
                const closestVertex = absB.closestVertexTo(p);
                const altCircum = absB.replaceVertexWith(closestVertex, p).calCircum();
                // Skip if there is no collision
                if (altCircum > origCircum) continue;

                // Update the state with the detected collision
                cA.value_ptr.append(self._allocator, .{
                    .face = B,
                    .x = closestVertex.x - p.x,
                    .y = closestVertex.y - p.y,
                    .z = closestVertex.z - p.z,
                }) catch unreachable;

                // Add collision to the B owner if and only if it didn't detect it already
                const found = blk: {
                    for (cB.value_ptr.items) |col|
                        if (col.face.owner == A.owner) break :blk true;
                    break :blk false;
                };
                if (!found) {
                    cB.value_ptr.append(self._allocator, .{
                        .face = A,
                        .x = p.x - closestVertex.x,
                        .y = p.y - closestVertex.y,
                        .z = p.z - closestVertex.z,
                    }) catch unreachable;
                }

                break;
            }
        }
    }
}
