
# uses geometry shader

using ModernGL, GeometryTypes, GLAbstraction, GLFW
const GLA = GLAbstraction

const RESOLUTION = (1200, 800)
const SPRITE_IMG_WIDTH = 16
const SPRITE_IMG_HEIGHT = 16
const SPRITE_SCALE = 5
const SPRITE_WIDTH = SPRITE_SCALE * SPRITE_IMG_WIDTH
const SPRITE_HEIGHT = SPRITE_SCALE * SPRITE_IMG_HEIGHT
const ROWS = div(RESOLUTION[2], SPRITE_HEIGHT)
const COLUMNS = div(RESOLUTION[1], SPRITE_WIDTH)

g_keys = Dict()

window = GLFW.Window(name="Snake game", resolution=RESOLUTION)
GLA.set_context!(window)

shader_program = GLA.Program(
    GLA.Shader(GL_VERTEX_SHADER, read("shader_vertex.glsl")), 
    GLA.Shader(GL_FRAGMENT_SHADER, read("shader_fragment.glsl")), 
    GLA.Shader(GL_GEOMETRY_SHADER, read("shader_geom.glsl")))


points = Point{3,Float32}[(0,  0, 0),     
                 (3*SPRITE_WIDTH,  2*SPRITE_HEIGHT, 1),     
                 (5*SPRITE_WIDTH,  4*SPRITE_HEIGHT, 4)
                 ]
                 

buffers = GLA.generate_buffers(shader_program, pos_img = points)
vao = GLA.VertexArray(GLA.SIMPLE, buffers)

GLFW.SetKeyCallback(window, (_, key, scancode, action, mods) -> begin
    if action == GLFW.PRESS
        g_keys[key] = true
    else
        g_keys[key] = false
    end
end)

glClearColor( 0.7, 0.7, 1, 0 )
t = 0
while !GLFW.WindowShouldClose(window)
    global t += 0.15
    glClearColor( 0.5*(1+sin(t)), 0.7, 1, 0 )
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    GLA.bind(shader_program)
    GLA.bind(vao)
    GLA.draw(vao)    
    GLFW.SwapBuffers(window)
    GLFW.PollEvents()
    GLFW.SetWindowShouldClose(window, get(g_keys, GLFW.KEY_ESCAPE, false))
end
GLFW.DestroyWindow(window)