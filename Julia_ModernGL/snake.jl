using ModernGL, GeometryTypes, GLAbstraction, GLFW

const RESOLUTION = (1200, 800)

window = GLFW.Window(name="Snake game", resolution=RESOLUTION)
GLAbstraction.set_context!(window)

shader_program = GLAbstraction.Program(
    GLAbstraction.Shader(GL_VERTEX_SHADER, read("shader_vertex.glsl")), 
    GLAbstraction.Shader(GL_FRAGMENT_SHADER, read("shader_fragment.glsl")), 
    GLAbstraction.Shader(GL_GEOMETRY_SHADER, read("shader_geom.glsl")))

