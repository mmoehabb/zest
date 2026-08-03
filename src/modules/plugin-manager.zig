//! All global static variable are stored and used in and from this component.
//! NOTE: Initializing and deinitializing this component shall only occur in the
//! screen component. You NEVER want to call these methods nor mutate the values of
//! these global variables.

const std = @import("std");

var initialized = false;
var plugins: ?std.StringHashMap(*anyopaque) = null;

pub fn init(allocator: std.mem.Allocator) !void {
    if (initialized) return;
    plugins = std.StringHashMap(*anyopaque).init(allocator);
    initialized = true;
}

pub fn deinit() void {
    plugins.?.deinit();
}

pub fn isInitialized() bool {
    return initialized;
}

pub fn add(plugin: *anyopaque, name: []const u8) !void {
    try plugins.?.put(name, plugin);
}

pub fn get(P: type, name: []const u8) ?*P {
    const found = plugins.?.get(name);
    if (found) |plugin| return @ptrCast(@alignCast(plugin));
    return null;
}
