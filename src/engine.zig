const std = @import("std");
const Allocator = std.mem.Allocator;
const c = @import("c.zig");
const glfw = c.glfw;
const gl = c.gl;
const math = @import("math.zig").math;
const Shader = @import("Shader.zig");
const Texture = @import("Texture.zig");
const Camera = @import("Camera.zig");

var wireframe: bool = false;
var cam: Camera = .init(.new(0.0, 2.0, 3.0), 5.0);
var delta_time: f32 = 0.0;
var mouse_pos: math.Vec2 = .zero;
var first_mouse: bool = true;

const VIEWPORT = math.vec2(800, 600);

// Viewport resize callback
fn frameBufferSizeCallback(_: ?*glfw.GLFWwindow, width: c_int, height: c_int) callconv(.c) void {
    gl.glViewport(0, 0, width, height);
}

fn cursorCallback(_: ?*glfw.GLFWwindow, x: f64, y: f64) callconv(.c) void {
    const xf: f32 = @floatCast(x);
    const yf: f32 = @floatCast(y);
    defer {
        mouse_pos.x = xf;
        mouse_pos.y = yf;
    }

    if (first_mouse) {
        first_mouse = false;
        return;
    }

    var x_offset = xf - mouse_pos.x;
    var y_offset = mouse_pos.y - yf; // reversed since y range from bottom to top

    const sensitivity = 0.1;
    x_offset *= sensitivity;
    y_offset *= sensitivity;

    cam.offsetYawPitch(x_offset, y_offset);
}

fn scrollCallback(_: ?*glfw.GLFWwindow, _: f64, y: f64) callconv(.c) void {
    cam.offsetFov(@floatCast(y));
}

fn keyCallback(win: ?*glfw.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.c) void {
    _ = scancode;
    _ = mods;

    if (key == glfw.GLFW_KEY_ESCAPE and action == glfw.GLFW_PRESS) {
        glfw.glfwSetWindowShouldClose(win, 1);
    }
    // qwerty for `z`
    else if (key == glfw.GLFW_KEY_W) {
        cam.moveForward(delta_time);
    }
    // qwerty for `s`
    else if (key == glfw.GLFW_KEY_S) {
        cam.moveBackward(delta_time);
    }
    // qwerty for `d`
    else if (key == glfw.GLFW_KEY_D) {
        cam.moveRight(delta_time);
    }
    // qwerty for `q`
    else if (key == glfw.GLFW_KEY_A) {
        cam.moveLeft(delta_time);
    }
    // qwerty for `w`
    else if (key == glfw.GLFW_KEY_Z and action == glfw.GLFW_RELEASE) {
        wireframe = !wireframe;
    }
}

pub fn setupWindow() void {
    if (glfw.glfwInit() == 0) {
        @panic("Failed to initialize GLFW window");
    }

    glfw.glfwWindowHint(glfw.GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfw.glfwWindowHint(glfw.GLFW_CONTEXT_VERSION_MINOR, 3);
    glfw.glfwWindowHint(glfw.GLFW_OPENGL_PROFILE, glfw.GLFW_OPENGL_CORE_PROFILE);

    if (@import("builtin").os.tag == .macos) {
        glfw.glfwWindowHint(glfw.GLFW_OPENGL_FORWARD_COMPAT, glfw.GL_TRUE);
    }

    const window = glfw.glfwCreateWindow(VIEWPORT.x, VIEWPORT.y, "LearnOpenGL", null, null) orelse {
        glfw.glfwTerminate();
        @panic("Failed to create GLFW window");
    };
    glfw.glfwMakeContextCurrent(window);

    // Mouse
    glfw.glfwSetInputMode(window, glfw.GLFW_CURSOR, glfw.GLFW_CURSOR_DISABLED);
    _ = glfw.glfwSetCursorPosCallback(window, cursorCallback);
    _ = glfw.glfwSetScrollCallback(window, scrollCallback);
    mouse_pos = VIEWPORT.scale(0.5);

    // Setup GLAD
    if (gl.gladLoadGLLoader(@ptrCast(&glfw.glfwGetProcAddress)) == 0) {
        @panic("Failed to initialize GLAD");
    }

    // Sets the viewport size. First two are lower left corner position
    gl.glViewport(0, 0, VIEWPORT.x, VIEWPORT.y);
    // Sets resize callback
    _ = glfw.glfwSetFramebufferSizeCallback(window, frameBufferSizeCallback);
    _ = glfw.glfwSetKeyCallback(window, keyCallback);

    const container_shader = Shader.init(
        @embedFile("assets/shaders/vert.glsl"),
        @embedFile("assets/shaders/frag.glsl"),
    );

    const light_shader = Shader.init(
        @embedFile("assets/shaders/light_vert.glsl"),
        @embedFile("assets/shaders/light_frag.glsl"),
    );

    // Data
    // zig fmt: off
    // Cube's vertices and normals
    const vertices = [_]f32{
        // positions       // normals        // texture coords
        -0.5, -0.5, -0.5,  0.0,  0.0, -1.0,  0.0,  0.0,
         0.5, -0.5, -0.5,  0.0,  0.0, -1.0,  1.0,  0.0,
         0.5,  0.5, -0.5,  0.0,  0.0, -1.0,  1.0,  1.0,
         0.5,  0.5, -0.5,  0.0,  0.0, -1.0,  1.0,  1.0,
        -0.5,  0.5, -0.5,  0.0,  0.0, -1.0,  0.0,  1.0,
        -0.5, -0.5, -0.5,  0.0,  0.0, -1.0,  0.0,  0.0,

        -0.5, -0.5,  0.5,  0.0,  0.0,  1.0,  0.0,  0.0,
         0.5, -0.5,  0.5,  0.0,  0.0,  1.0,  1.0,  0.0,
         0.5,  0.5,  0.5,  0.0,  0.0,  1.0,  1.0,  1.0,
         0.5,  0.5,  0.5,  0.0,  0.0,  1.0,  1.0,  1.0,
        -0.5,  0.5,  0.5,  0.0,  0.0,  1.0,  0.0,  1.0,
        -0.5, -0.5,  0.5,  0.0,  0.0,  1.0,  0.0,  0.0,

        -0.5,  0.5,  0.5, -1.0,  0.0,  0.0,  1.0,  0.0,
        -0.5,  0.5, -0.5, -1.0,  0.0,  0.0,  1.0,  1.0,
        -0.5, -0.5, -0.5, -1.0,  0.0,  0.0,  0.0,  1.0,
        -0.5, -0.5, -0.5, -1.0,  0.0,  0.0,  0.0,  1.0,
        -0.5, -0.5,  0.5, -1.0,  0.0,  0.0,  0.0,  0.0,
        -0.5,  0.5,  0.5, -1.0,  0.0,  0.0,  1.0,  0.0,

         0.5,  0.5,  0.5,  1.0,  0.0,  0.0,  1.0,  0.0,
         0.5,  0.5, -0.5,  1.0,  0.0,  0.0,  1.0,  1.0,
         0.5, -0.5, -0.5,  1.0,  0.0,  0.0,  0.0,  1.0,
         0.5, -0.5, -0.5,  1.0,  0.0,  0.0,  0.0,  1.0,
         0.5, -0.5,  0.5,  1.0,  0.0,  0.0,  0.0,  0.0,
         0.5,  0.5,  0.5,  1.0,  0.0,  0.0,  1.0,  0.0,

        -0.5, -0.5, -0.5,  0.0, -1.0,  0.0,  0.0,  1.0,
         0.5, -0.5, -0.5,  0.0, -1.0,  0.0,  1.0,  1.0,
         0.5, -0.5,  0.5,  0.0, -1.0,  0.0,  1.0,  0.0,
         0.5, -0.5,  0.5,  0.0, -1.0,  0.0,  1.0,  0.0,
        -0.5, -0.5,  0.5,  0.0, -1.0,  0.0,  0.0,  0.0,
        -0.5, -0.5, -0.5,  0.0, -1.0,  0.0,  0.0,  1.0,

        -0.5,  0.5, -0.5,  0.0,  1.0,  0.0,  0.0,  1.0,
         0.5,  0.5, -0.5,  0.0,  1.0,  0.0,  1.0,  1.0,
         0.5,  0.5,  0.5,  0.0,  1.0,  0.0,  1.0,  0.0,
         0.5,  0.5,  0.5,  0.0,  1.0,  0.0,  1.0,  0.0,
        -0.5,  0.5,  0.5,  0.0,  1.0,  0.0,  0.0,  0.0,
        -0.5,  0.5, -0.5,  0.0,  1.0,  0.0,  0.0,  1.0,
    };
    // zig fmt: on

    const cubes_pos = [_]math.Vec3{
        math.vec3(-2.0, 0.0, -5.0),
    };

    // Initialization code (done once (unless your object frequently changes))
    // 1. bind Vertex Array Object
    var vao: c_uint = 0;
    gl.glGenVertexArrays(1, &vao);
    // We bind this vao so it remembers all other configurations of the vbo
    gl.glBindVertexArray(vao);

    // Vertex Buffer Object
    var vbo: c_uint = 0;
    gl.glGenBuffers(1, &vbo);
    // Binds it to type ARRAY_BUFFER
    // From that point on any buffer calls we make (on the GL_ARRAY_BUFFER target) will be used
    // to configure the currently bound buffer, which is VBO.
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, vbo);
    // Copy the data to the target
    gl.glBufferData(gl.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, gl.GL_STATIC_DRAW);

    // First arg correspond to `location 0` in our shader
    // Second is size of attribute, we use vec3
    // Thirs type of data
    // We don't want normalization of our data
    // Stride/padding between our data. The array is tightly packed
    // Offset of where the position data begins in the buffer
    gl.glVertexAttribPointer(0, 3, gl.GL_FLOAT, gl.GL_FALSE, 8 * @sizeOf(f32), @ptrFromInt(0));
    gl.glEnableVertexAttribArray(0);
    gl.glVertexAttribPointer(1, 3, gl.GL_FLOAT, gl.GL_FALSE, 8 * @sizeOf(f32), @ptrFromInt(3 * @sizeOf(f32)));
    gl.glEnableVertexAttribArray(1);
    gl.glVertexAttribPointer(2, 2, gl.GL_FLOAT, gl.GL_FALSE, 8 * @sizeOf(f32), @ptrFromInt(6 * @sizeOf(f32)));
    gl.glEnableVertexAttribArray(2);

    // Tell the shader which sampler has which
    container_shader.use();

    const light_pos: math.Vec3 = math.vec3(-2.0, 2.0, -2.0);
    container_shader.setVec3("light.position", light_pos);
    container_shader.setVec3("light.ambient", .new(0.2, 0.2, 0.2));
    container_shader.setVec3("light.diffuse", .new(0.5, 0.5, 0.5));
    container_shader.setVec3("light.specular", .new(1.0, 1.0, 1.0));
    container_shader.setFloat("material.shininess", 64.0);

    container_shader.setInt("material.diffuse", 0);
    const diffuse_map = Texture.create("assets/container2.png", .rgba);

    container_shader.setInt("material.specular", 1);
    const specular_map = Texture.create("assets/container2_specular.png", .rgba);

    // Lights
    var light_vao: u32 = 0;
    gl.glGenVertexArrays(1, &light_vao);
    gl.glBindVertexArray(light_vao);
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, vbo);
    gl.glVertexAttribPointer(0, 3, gl.GL_FLOAT, gl.GL_FALSE, 8 * @sizeOf(f32), @ptrFromInt(0));
    gl.glEnableVertexAttribArray(0);

    gl.glEnable(gl.GL_DEPTH_TEST);

    var last_frame: f32 = 0.0;

    while (glfw.glfwWindowShouldClose(window) == 0) {
        glfw.glfwPollEvents();

        gl.glPolygonMode(gl.GL_FRONT_AND_BACK, if (wireframe) gl.GL_LINE else gl.GL_FILL);

        gl.glClearColor(0.2, 0.3, 0.3, 1.0);
        gl.glClear(gl.GL_COLOR_BUFFER_BIT | gl.GL_DEPTH_BUFFER_BIT);

        // To tell we use those shaders
        container_shader.use();
        // Invokes the vao (which contains all the vbo sub-calls)
        // gl.glBindTexture(gl.GL_TEXTURE_2D, tex1);
        gl.glBindVertexArray(vao);

        // Bind first two of 16 available texture slots
        // gl.glActiveTexture(gl.GL_TEXTURE0);
        // gl.glBindTexture(gl.GL_TEXTURE_2D, tex1);
        // gl.glActiveTexture(gl.GL_TEXTURE1);
        // gl.glBindTexture(gl.GL_TEXTURE_2D, tex2);

        // Add data to uniform
        const time: f32 = @floatCast(glfw.glfwGetTime());
        delta_time = time - last_frame;
        last_frame = time;

        const view = cam.getLookAt();
        container_shader.setMat4f("view", view);

        const projection = math.Mat4.createPerspective(math.toRadians(cam.fov), VIEWPORT.x / VIEWPORT.y, 0.1, 100.0);
        container_shader.setMat4f("projection", projection);

        container_shader.setVec3("viewPos", cam.pos);
        // container_shader.setVec3("material.ambient", .new(1.0, 0.5, 0.31));
        container_shader.setVec3("material.diffuse", .new(1.0, 0.5, 0.31));
        container_shader.setVec3("material.specular", .new(0.5, 0.5, 0.5));
        container_shader.setFloat("material.shininess", 32.0);

        gl.glActiveTexture(gl.GL_TEXTURE0);
        gl.glBindTexture(gl.GL_TEXTURE_2D, diffuse_map);
        gl.glActiveTexture(gl.GL_TEXTURE1);
        gl.glBindTexture(gl.GL_TEXTURE_2D, specular_map);

        for (cubes_pos, 0..) |pos, i| {
            _ = pos; // autofix
            const model = math.Mat4.identity;
            const angle = 20.0 * @as(f32, @floatFromInt(i));
            _ = angle; // autofix

            // Or do in reverse order w/r tutorial but I think it's the correct way, always rotate before translating
            // model = model.mul(.createAngleAxis(math.vec3(1.0, 0.3, 0.5), math.toRadians(angle)));
            // model = model.mul(.createTranslation(pos));

            container_shader.setMat4f("model", model);

            // Draw
            gl.glDrawArrays(gl.GL_TRIANGLES, 0, 36);
        }

        // Draw elements based on the indicies. Second args is number of elems and last is the offset
        // gl.glDrawElements(gl.GL_TRIANGLES, 6, gl.GL_UNSIGNED_INT, @ptrFromInt(0));

        // Lights
        {
            const model = math.Mat4.batchMul(&.{
                .createUniformScale(0.2),
                .createTranslation(light_pos),
            });

            light_shader.use();
            light_shader.setMat4f("view", view);
            light_shader.setMat4f("projection", projection);
            light_shader.setMat4f("model", model);

            gl.glBindVertexArray(light_vao);
            gl.glDrawArrays(gl.GL_TRIANGLES, 0, 36);
        }

        glfw.glfwSwapBuffers(window);
    }

    glfw.glfwTerminate();
}
