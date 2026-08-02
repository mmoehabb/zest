const Face = @import("./face.zig");

/// The face that this object collides with.
face: Face,
/// The x distance which the object shall move in order to get outside the face.
x: f32,
/// The y distance which the object shall move in order to get outside the face.
y: f32,
/// The z distance which the object shall move in order to get outside the face.
z: f32,
