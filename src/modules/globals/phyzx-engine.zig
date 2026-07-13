const std = @import("std");
const Object = @import("../object.zig");
const Mesh = @import("../../scripts/mesh.zig");
const Face = @import("../../types/face.zig");
const Position = @import("../../types/position.zig");

const PhyzxEngine = @This();

_io: std.Io,
_allocator: std.mem.Allocator,
_thread: ?std.Thread = null,
_deinitializing: bool = false,

_objects: std.ArrayList(*Object) = .empty,
_collisionMap: std.AutoHashMap(*Object, std.ArrayList(*Object)),

/// NOTE: This is used as a buffer, in order to optimize the detection thread
/// execution, by avoiding constantly allocating and deallocating memory.
_faces: std.ArrayList(Face) = .empty,

/// Used before retrieving or manipulating any state (data) used in the detection thread.
_state_mutex: std.Io.Mutex = .init,
_map_mutex: std.Io.Mutex = .init,

pub fn init(allocator: std.mem.Allocator, io: std.Io) PhyzxEngine {
    return PhyzxEngine{
        ._io = io,
        ._allocator = allocator,
        ._collisionMap = std.AutoHashMap(*Object, std.ArrayList(*Object)).init(allocator),
    };
}

pub fn start(self: *PhyzxEngine) !void {
    self._thread = try std.Thread.spawn(.{}, detectCollisionThread, .{self});
}

pub fn deinit(self: *PhyzxEngine) void {
    self._deinitializing = true;
    if (self._thread) |thread| thread.join();

    var iter = self._collisionMap.valueIterator();
    while (iter.next()) |v| v.deinit(self._allocator);
    self._collisionMap.deinit();

    self._objects.deinit(self._allocator);
    self._faces.deinit(self._allocator);
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

/// Get a slice of objects that collides with the passed _obj_ parameter.
pub fn getCollisions(self: *PhyzxEngine, obj: *Object, buf: []?*Object) !void {
    try self._map_mutex.lock(self._io);
    defer self._map_mutex.unlock(self._io);
    const res = try self._collisionMap.getOrPutValue(obj, .empty);
    @memcpy(buf[0..res.value_ptr.items.len], res.value_ptr.items);
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
    self._io.sleep(.fromMilliseconds(24), .awake) catch {
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
    var iter = self._collisionMap.valueIterator();
    while (iter.next()) |e| e.clearRetainingCapacity();

    // Apply the collision detection algorithm for each face
    for (self._faces.items) |A| {
        self._map_mutex.lock(self._io) catch unreachable;
        for (self._faces.items) |B| {
            if (A.owner == B.owner) continue;
            const absA = A.add(A.owner.position);
            const absB = B.add(B.owner.position);

            // TODO: enhance error hanlding
            const e1 = self._collisionMap.getOrPutValue(A.owner, .empty) catch unreachable;
            const e2 = self._collisionMap.getOrPutValue(B.owner, .empty) catch unreachable;

            inline for ([4]Position{ absA.p1, absA.p2, absA.p3, absA.p4 }) |p| {
                if (absB.isPCP(p)) {
                    const origCircum = absB.calCircum();
                    const altCircum = absB.getAlter(p).calCircum();
                    if (altCircum <= origCircum) {
                        e1.value_ptr.append(self._allocator, B.owner) catch unreachable;
                        e2.value_ptr.append(self._allocator, A.owner) catch unreachable;
                    }
                }
            }
        }
        self._map_mutex.unlock(self._io);
    }
}
