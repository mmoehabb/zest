//! This component is responsible for managing different key events (e.g. keyboard events).
//! [The screen component](#root.modules.screen) automatically initializes and deinitializes it,
//! and exposes it via the [getEventManager](#root.modules.screen.getEventManager) method.

const std = @import("std");
const sdl = @import("sdl");

const types = @import("../types/mod.zig");
const Key = @import("../types/event.zig").Key;
const KeyState = @import("../types/event.zig").KeyState;

const EventManager = @This();

_keys: std.AutoHashMap(Key, KeyState),
_mouse_pos: types.Vector = types.Vector{},
_allocator: std.mem.Allocator,

_text_input_buf: [32]u8 = @splat(0),
_text_input_cursor: usize = 0,
_activeWindow: ?*sdl.SDL_Window = null,

pub fn init(allocator: std.mem.Allocator) EventManager {
    return EventManager{
        ._keys = std.AutoHashMap(Key, KeyState).init(allocator),
        ._allocator = allocator,
    };
}

pub fn deinit(self: *EventManager) void {
    self._keys.deinit();
}

pub fn getKeys(self: *EventManager) std.AutoHashMap(Key, KeyState) {
    return self._keys;
}

pub fn isKeyDown(self: *EventManager, key: Key) bool {
    const state = self._keys.get(key) orelse .Up;
    return state == .Down;
}

pub fn isKeyUp(self: *EventManager, key: Key) bool {
    const state = self._keys.get(key) orelse .Up;
    return state == .Up;
}

pub fn getMousePos(self: *EventManager) types.Vector {
    return self._mouse_pos;
}

pub fn isMouseDown(self: *EventManager) bool {
    return self.isKeyDown(.LeftMouse);
}

pub fn isMouseUp(self: *EventManager) bool {
    return self.isKeyUp(.LeftMouse);
}

pub fn setActiveWindow(self: *EventManager, window: ?*sdl.SDL_Window) void {
    self._activeWindow = window;
}

/// Returns and clears the text typed since the last call. Each call returns the
/// accumulated UTF-8 bytes from all SDL_EVENT_TEXT_INPUT events processed during
/// the most recent [invokeEventLoop](#root.modules.eventmanager.invokeventloop) call.
pub fn drainTextInput(self: *EventManager) []const u8 {
    defer self._text_input_cursor = 0;
    return self._text_input_buf[0..self._text_input_cursor];
}

/// Invokes SDL_PollEvent and mutates the _keys field state accordingly. This method
/// shall only be invoked by the [screen](#root.modules.screen) instance. No need to
/// manually calling it.
pub fn invokeEventLoop(self: *EventManager) !sdl.SDL_Event {
    var event: sdl.SDL_Event = undefined;
    while (sdl.SDL_PollEvent(&event)) {
        switch (event.type) {
            sdl.SDL_EVENT_KEY_DOWN => {
                const key = scancodeToKey(event.key.scancode);
                try self.keyDown(key);
            },
            sdl.SDL_EVENT_KEY_UP => {
                const key = scancodeToKey(event.key.scancode);
                try self.keyUp(key);
            },
            sdl.SDL_EVENT_MOUSE_MOTION => {
                self._mouse_pos = .{
                    .x = event.motion.x,
                    .y = event.motion.y,
                };
            },
            sdl.SDL_EVENT_TEXT_INPUT => {
                const slice: []const u8 = std.mem.span(event.text.text);
                const s = self._text_input_cursor;
                const e = s + slice.len;
                @memcpy(self._text_input_buf[s..e], slice);
                self._text_input_cursor = e;
            },
            sdl.SDL_EVENT_MOUSE_BUTTON_DOWN => {
                const key = mouseCodeToEnum(event.button.button);
                try self.keyDown(key);
                return event;
            },
            sdl.SDL_EVENT_MOUSE_BUTTON_UP => {
                const key = mouseCodeToEnum(event.button.button);
                try self.keyUp(key);
                return event;
            },
            else => return event,
        }
    }
    return event;
}

fn keyDown(self: *EventManager, key: Key) !void {
    try self._keys.put(key, .Down);
}

fn keyUp(self: *EventManager, key: Key) !void {
    try self._keys.put(key, .Up);
}

fn scancodeToKey(scancode: sdl.SDL_Scancode) Key {
    return switch (scancode) {
        sdl.SDL_SCANCODE_UNKNOWN => .Unknown,
        sdl.SDL_SCANCODE_A => .A,
        sdl.SDL_SCANCODE_B => .B,
        sdl.SDL_SCANCODE_C => .C,
        sdl.SDL_SCANCODE_D => .D,
        sdl.SDL_SCANCODE_E => .E,
        sdl.SDL_SCANCODE_F => .F,
        sdl.SDL_SCANCODE_G => .G,
        sdl.SDL_SCANCODE_H => .H,
        sdl.SDL_SCANCODE_I => .I,
        sdl.SDL_SCANCODE_J => .J,
        sdl.SDL_SCANCODE_K => .K,
        sdl.SDL_SCANCODE_L => .L,
        sdl.SDL_SCANCODE_M => .M,
        sdl.SDL_SCANCODE_N => .N,
        sdl.SDL_SCANCODE_O => .O,
        sdl.SDL_SCANCODE_P => .P,
        sdl.SDL_SCANCODE_Q => .Q,
        sdl.SDL_SCANCODE_R => .R,
        sdl.SDL_SCANCODE_S => .S,
        sdl.SDL_SCANCODE_T => .T,
        sdl.SDL_SCANCODE_U => .U,
        sdl.SDL_SCANCODE_V => .V,
        sdl.SDL_SCANCODE_W => .W,
        sdl.SDL_SCANCODE_X => .X,
        sdl.SDL_SCANCODE_Y => .Y,
        sdl.SDL_SCANCODE_Z => .Z,
        sdl.SDL_SCANCODE_0 => .Num0,
        sdl.SDL_SCANCODE_1 => .Num1,
        sdl.SDL_SCANCODE_2 => .Num2,
        sdl.SDL_SCANCODE_3 => .Num3,
        sdl.SDL_SCANCODE_4 => .Num4,
        sdl.SDL_SCANCODE_5 => .Num5,
        sdl.SDL_SCANCODE_6 => .Num6,
        sdl.SDL_SCANCODE_7 => .Num7,
        sdl.SDL_SCANCODE_8 => .Num8,
        sdl.SDL_SCANCODE_9 => .Num9,
        sdl.SDL_SCANCODE_RETURN => .Return,
        sdl.SDL_SCANCODE_ESCAPE => .Escape,
        sdl.SDL_SCANCODE_BACKSPACE => .Backspace,
        sdl.SDL_SCANCODE_TAB => .Tab,
        sdl.SDL_SCANCODE_SPACE => .Space,
        sdl.SDL_SCANCODE_MINUS => .Minus,
        sdl.SDL_SCANCODE_EQUALS => .Equals,
        sdl.SDL_SCANCODE_LEFTBRACKET => .LeftBracket,
        sdl.SDL_SCANCODE_RIGHTBRACKET => .RightBracket,
        sdl.SDL_SCANCODE_BACKSLASH => .Backslash,
        sdl.SDL_SCANCODE_NONUSHASH => .NonUsHash,
        sdl.SDL_SCANCODE_SEMICOLON => .Semicolon,
        sdl.SDL_SCANCODE_APOSTROPHE => .Apostrophe,
        sdl.SDL_SCANCODE_GRAVE => .Grave,
        sdl.SDL_SCANCODE_COMMA => .Comma,
        sdl.SDL_SCANCODE_PERIOD => .Period,
        sdl.SDL_SCANCODE_SLASH => .Slash,
        sdl.SDL_SCANCODE_CAPSLOCK => .CapsLock,
        sdl.SDL_SCANCODE_F1 => .F1,
        sdl.SDL_SCANCODE_F2 => .F2,
        sdl.SDL_SCANCODE_F3 => .F3,
        sdl.SDL_SCANCODE_F4 => .F4,
        sdl.SDL_SCANCODE_F5 => .F5,
        sdl.SDL_SCANCODE_F6 => .F6,
        sdl.SDL_SCANCODE_F7 => .F7,
        sdl.SDL_SCANCODE_F8 => .F8,
        sdl.SDL_SCANCODE_F9 => .F9,
        sdl.SDL_SCANCODE_F10 => .F10,
        sdl.SDL_SCANCODE_F11 => .F11,
        sdl.SDL_SCANCODE_F12 => .F12,
        sdl.SDL_SCANCODE_PRINTSCREEN => .PrintScreen,
        sdl.SDL_SCANCODE_SCROLLLOCK => .ScrollLock,
        sdl.SDL_SCANCODE_PAUSE => .Pause,
        sdl.SDL_SCANCODE_INSERT => .Insert,
        sdl.SDL_SCANCODE_HOME => .Home,
        sdl.SDL_SCANCODE_PAGEUP => .PageUp,
        sdl.SDL_SCANCODE_DELETE => .Delete,
        sdl.SDL_SCANCODE_END => .End,
        sdl.SDL_SCANCODE_PAGEDOWN => .PageDown,
        sdl.SDL_SCANCODE_RIGHT => .Right,
        sdl.SDL_SCANCODE_LEFT => .Left,
        sdl.SDL_SCANCODE_DOWN => .Down,
        sdl.SDL_SCANCODE_UP => .Up,
        sdl.SDL_SCANCODE_NUMLOCKCLEAR => .NumLockClear,
        sdl.SDL_SCANCODE_KP_DIVIDE => .KpDivide,
        sdl.SDL_SCANCODE_KP_MULTIPLY => .KpMultiply,
        sdl.SDL_SCANCODE_KP_MINUS => .KpMinus,
        sdl.SDL_SCANCODE_KP_PLUS => .KpPlus,
        sdl.SDL_SCANCODE_KP_ENTER => .KpEnter,
        sdl.SDL_SCANCODE_KP_1 => .Kp1,
        sdl.SDL_SCANCODE_KP_2 => .Kp2,
        sdl.SDL_SCANCODE_KP_3 => .Kp3,
        sdl.SDL_SCANCODE_KP_4 => .Kp4,
        sdl.SDL_SCANCODE_KP_5 => .Kp5,
        sdl.SDL_SCANCODE_KP_6 => .Kp6,
        sdl.SDL_SCANCODE_KP_7 => .Kp7,
        sdl.SDL_SCANCODE_KP_8 => .Kp8,
        sdl.SDL_SCANCODE_KP_9 => .Kp9,
        sdl.SDL_SCANCODE_KP_0 => .Kp0,
        sdl.SDL_SCANCODE_KP_PERIOD => .KpPeriod,
        sdl.SDL_SCANCODE_NONUSBACKSLASH => .NonUsBackslash,
        sdl.SDL_SCANCODE_APPLICATION => .Application,
        sdl.SDL_SCANCODE_POWER => .Power,
        sdl.SDL_SCANCODE_KP_EQUALS => .KpEquals,
        sdl.SDL_SCANCODE_F13 => .F13,
        sdl.SDL_SCANCODE_F14 => .F14,
        sdl.SDL_SCANCODE_F15 => .F15,
        sdl.SDL_SCANCODE_F16 => .F16,
        sdl.SDL_SCANCODE_F17 => .F17,
        sdl.SDL_SCANCODE_F18 => .F18,
        sdl.SDL_SCANCODE_F19 => .F19,
        sdl.SDL_SCANCODE_F20 => .F20,
        sdl.SDL_SCANCODE_F21 => .F21,
        sdl.SDL_SCANCODE_F22 => .F22,
        sdl.SDL_SCANCODE_F23 => .F23,
        sdl.SDL_SCANCODE_F24 => .F24,
        sdl.SDL_SCANCODE_EXECUTE => .Execute,
        sdl.SDL_SCANCODE_HELP => .Help,
        sdl.SDL_SCANCODE_MENU => .Menu,
        sdl.SDL_SCANCODE_SELECT => .Select,
        sdl.SDL_SCANCODE_STOP => .Stop,
        sdl.SDL_SCANCODE_AGAIN => .Again,
        sdl.SDL_SCANCODE_UNDO => .Undo,
        sdl.SDL_SCANCODE_CUT => .Cut,
        sdl.SDL_SCANCODE_COPY => .Copy,
        sdl.SDL_SCANCODE_PASTE => .Paste,
        sdl.SDL_SCANCODE_FIND => .Find,
        sdl.SDL_SCANCODE_MUTE => .Mute,
        sdl.SDL_SCANCODE_VOLUMEUP => .VolumeUp,
        sdl.SDL_SCANCODE_VOLUMEDOWN => .VolumeDown,
        sdl.SDL_SCANCODE_KP_COMMA => .KpComma,
        sdl.SDL_SCANCODE_KP_EQUALSAS400 => .KpEqualsAS400,
        sdl.SDL_SCANCODE_INTERNATIONAL1 => .International1,
        sdl.SDL_SCANCODE_INTERNATIONAL2 => .International2,
        sdl.SDL_SCANCODE_INTERNATIONAL3 => .International3,
        sdl.SDL_SCANCODE_INTERNATIONAL4 => .International4,
        sdl.SDL_SCANCODE_INTERNATIONAL5 => .International5,
        sdl.SDL_SCANCODE_INTERNATIONAL6 => .International6,
        sdl.SDL_SCANCODE_INTERNATIONAL7 => .International7,
        sdl.SDL_SCANCODE_INTERNATIONAL8 => .International8,
        sdl.SDL_SCANCODE_INTERNATIONAL9 => .International9,
        sdl.SDL_SCANCODE_LANG1 => .Lang1,
        sdl.SDL_SCANCODE_LANG2 => .Lang2,
        sdl.SDL_SCANCODE_LANG3 => .Lang3,
        sdl.SDL_SCANCODE_LANG4 => .Lang4,
        sdl.SDL_SCANCODE_LANG5 => .Lang5,
        sdl.SDL_SCANCODE_LANG6 => .Lang6,
        sdl.SDL_SCANCODE_LANG7 => .Lang7,
        sdl.SDL_SCANCODE_LANG8 => .Lang8,
        sdl.SDL_SCANCODE_LANG9 => .Lang9,
        sdl.SDL_SCANCODE_ALTERASE => .AltErase,
        sdl.SDL_SCANCODE_SYSREQ => .SysReq,
        sdl.SDL_SCANCODE_CANCEL => .Cancel,
        sdl.SDL_SCANCODE_CLEAR => .Clear,
        sdl.SDL_SCANCODE_PRIOR => .Prior,
        sdl.SDL_SCANCODE_RETURN2 => .Return2,
        sdl.SDL_SCANCODE_SEPARATOR => .Separator,
        sdl.SDL_SCANCODE_OUT => .Out,
        sdl.SDL_SCANCODE_OPER => .Oper,
        sdl.SDL_SCANCODE_CLEARAGAIN => .ClearAgain,
        sdl.SDL_SCANCODE_CRSEL => .CrSel,
        sdl.SDL_SCANCODE_EXSEL => .ExSel,
        sdl.SDL_SCANCODE_KP_00 => .Kp00,
        sdl.SDL_SCANCODE_KP_000 => .Kp000,
        sdl.SDL_SCANCODE_THOUSANDSSEPARATOR => .ThousandsSeparator,
        sdl.SDL_SCANCODE_DECIMALSEPARATOR => .DecimalSeparator,
        sdl.SDL_SCANCODE_CURRENCYUNIT => .CurrencyUnit,
        sdl.SDL_SCANCODE_CURRENCYSUBUNIT => .CurrencySubUnit,
        sdl.SDL_SCANCODE_KP_LEFTPAREN => .KpLeftParen,
        sdl.SDL_SCANCODE_KP_RIGHTPAREN => .KpRightParen,
        sdl.SDL_SCANCODE_KP_LEFTBRACE => .KpLeftBrace,
        sdl.SDL_SCANCODE_KP_RIGHTBRACE => .KpRightBrace,
        sdl.SDL_SCANCODE_KP_TAB => .KpTab,
        sdl.SDL_SCANCODE_KP_BACKSPACE => .KpBackspace,
        sdl.SDL_SCANCODE_KP_A => .KpA,
        sdl.SDL_SCANCODE_KP_B => .KpB,
        sdl.SDL_SCANCODE_KP_C => .KpC,
        sdl.SDL_SCANCODE_KP_D => .KpD,
        sdl.SDL_SCANCODE_KP_E => .KpE,
        sdl.SDL_SCANCODE_KP_F => .KpF,
        sdl.SDL_SCANCODE_KP_XOR => .KpXor,
        sdl.SDL_SCANCODE_KP_POWER => .KpPower,
        sdl.SDL_SCANCODE_KP_PERCENT => .KpPercent,
        sdl.SDL_SCANCODE_KP_LESS => .KpLess,
        sdl.SDL_SCANCODE_KP_GREATER => .KpGreater,
        sdl.SDL_SCANCODE_KP_AMPERSAND => .KpAmpersand,
        sdl.SDL_SCANCODE_KP_DBLAMPERSAND => .KpDblAmpersand,
        sdl.SDL_SCANCODE_KP_VERTICALBAR => .KpVerticalBar,
        sdl.SDL_SCANCODE_KP_DBLVERTICALBAR => .KpDblVerticalBar,
        sdl.SDL_SCANCODE_KP_COLON => .KpColon,
        sdl.SDL_SCANCODE_KP_HASH => .KpHash,
        sdl.SDL_SCANCODE_KP_SPACE => .KpSpace,
        sdl.SDL_SCANCODE_KP_AT => .KpAt,
        sdl.SDL_SCANCODE_KP_EXCLAM => .KpExclam,
        sdl.SDL_SCANCODE_KP_MEMSTORE => .KpMemStore,
        sdl.SDL_SCANCODE_KP_MEMRECALL => .KpMemRecall,
        sdl.SDL_SCANCODE_KP_MEMCLEAR => .KpMemClear,
        sdl.SDL_SCANCODE_KP_MEMADD => .KpMemAdd,
        sdl.SDL_SCANCODE_KP_MEMSUBTRACT => .KpMemSubtract,
        sdl.SDL_SCANCODE_KP_MEMMULTIPLY => .KpMemMultiply,
        sdl.SDL_SCANCODE_KP_MEMDIVIDE => .KpMemDivide,
        sdl.SDL_SCANCODE_KP_PLUSMINUS => .KpPlusMinus,
        sdl.SDL_SCANCODE_KP_CLEAR => .KpClear,
        sdl.SDL_SCANCODE_KP_CLEARENTRY => .KpClearEntry,
        sdl.SDL_SCANCODE_KP_BINARY => .KpBinary,
        sdl.SDL_SCANCODE_KP_OCTAL => .KpOctal,
        sdl.SDL_SCANCODE_KP_DECIMAL => .KpDecimal,
        sdl.SDL_SCANCODE_KP_HEXADECIMAL => .KpHexadecimal,
        sdl.SDL_SCANCODE_LCTRL => .LCtrl,
        sdl.SDL_SCANCODE_LSHIFT => .LShift,
        sdl.SDL_SCANCODE_LALT => .LAlt,
        sdl.SDL_SCANCODE_LGUI => .LGui,
        sdl.SDL_SCANCODE_RCTRL => .RCtrl,
        sdl.SDL_SCANCODE_RSHIFT => .RShift,
        sdl.SDL_SCANCODE_RALT => .RAlt,
        sdl.SDL_SCANCODE_RGUI => .RGui,
        sdl.SDL_SCANCODE_MODE => .Mode,
        sdl.SDL_SCANCODE_AC_SEARCH => .AcSearch,
        sdl.SDL_SCANCODE_AC_HOME => .AcHome,
        sdl.SDL_SCANCODE_AC_BACK => .AcBack,
        sdl.SDL_SCANCODE_AC_FORWARD => .AcForward,
        sdl.SDL_SCANCODE_AC_STOP => .AcStop,
        sdl.SDL_SCANCODE_AC_REFRESH => .AcRefresh,
        sdl.SDL_SCANCODE_AC_BOOKMARKS => .AcBookmarks,
        else => .Unknown,
    };
}

fn mouseCodeToEnum(scancode: sdl.SDL_Scancode) Key {
    return switch (scancode) {
        sdl.SDL_BUTTON_LEFT => .LeftMouse,
        sdl.SDL_BUTTON_MIDDLE => .MiddleMouse,
        sdl.SDL_BUTTON_RIGHT => .RightMouse,
        sdl.SDL_BUTTON_X1 => .X1Mouse,
        sdl.SDL_BUTTON_X2 => .X2Mouse,
        else => .LeftMouse, // NOTE: any unknown mouse click event considered as a left click
    };
}

test "Putting new key state in the map" {
    const expect = std.testing.expect;
    var em = EventManager.init(std.testing.allocator);
    defer em.deinit();

    try em.keyDown(Key.A);
    try expect(em.getKeys().get(Key.A) == .Down);
}

test "Updating a key state in the map" {
    const expect = std.testing.expect;
    var em = EventManager.init(std.testing.allocator);
    defer em.deinit();

    try em.keyDown(Key.D);
    try expect(em.getKeys().get(Key.D) == .Down);

    try em.keyUp(Key.D);
    try expect(em.getKeys().get(Key.D) == .Up);
}

test "Default key state should be Up" {
    const expect = std.testing.expect;
    var em = EventManager.init(std.testing.allocator);
    defer em.deinit();

    try expect(em.isKeyUp(Key.S) == true);
    try expect(em.isKeyDown(Key.S) == false);

    try em.keyDown(Key.S);
    try expect(em.isKeyUp(Key.S) == false);
    try expect(em.isKeyDown(Key.S) == true);
}
