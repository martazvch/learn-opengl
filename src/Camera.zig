const math = @import("math.zig").math;

pos: math.Vec3,
speed: f32,
dir: math.Vec3,
yaw: f32,
pitch: f32,
fov: f32,

const Self = @This();
const UP = math.Vec3.unitY;

pub fn init(pos: math.Vec3, speed: f32) Self {
    // We init yaw at -90 because angle is from +x axis (pointing to the right) to +z
    var self: Self = .{
        .pos = pos,
        .speed = speed,
        .dir = undefined,
        .yaw = -90.0,
        .pitch = 0.0,
        .fov = 45,
    };
    self.orient();
    return self;
}

pub fn moveForward(self: *Self, factor: f32) void {
    self.pos = self.pos.add(self.dir.scale(self.speed * factor));
}

pub fn moveBackward(self: *Self, factor: f32) void {
    self.pos = self.pos.sub(self.dir.scale(self.speed * factor));
}

pub fn moveLeft(self: *Self, factor: f32) void {
    self.pos = self.pos.sub(
        self.dir.cross(UP).normalize().scale(self.speed * factor),
    );
}

pub fn moveRight(self: *Self, factor: f32) void {
    self.pos = self.pos.add(
        self.dir.cross(UP).normalize().scale(self.speed * factor),
    );
}

pub fn getLookAt(self: *const Self) math.Mat4 {
    return .createLookAt(self.pos, self.pos.add(self.dir), UP);
}

pub fn offsetYawPitch(self: *Self, yaw: f32, pitch: f32) void {
    self.yaw += yaw;
    self.pitch += pitch;

    if (self.pitch > 89.0) {
        self.pitch = 89.0;
    } else if (self.pitch < -89.0) {
        self.pitch = -89.0;
    }

    self.orient();
}

pub fn orient(self: *Self) void {
    self.dir.x = @cos(math.toRadians(self.yaw)) * @cos(math.toRadians(self.pitch));
    self.dir.y = @sin(math.toRadians(self.pitch));
    self.dir.z = @sin(math.toRadians(self.yaw)) * @cos(math.toRadians(self.pitch));
    self.dir = self.dir.normalize();
}

pub fn offsetFov(self: *Self, offset: f32) void {
    self.fov -= offset;

    if (self.fov < 1.0) {
        self.fov = 1.0;
    } else if (self.fov > 45.0) {
        self.fov = 45.0;
    }
}
