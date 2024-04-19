function ortho_projection(left::Float32, right::Float32, bottom::Float32, top::Float32, near::Float32, far::Float32)
    T0, T1 = zero(Float32), one(Float32)
    Mat4{Float32}(
        2 / (right - left), T0, T0, T0,
        T0, 2 / (top - bottom), T0, T0, 
        T0, T0, T1 / (far - near), T0,
        - (right + left) / (right - left), - (top + bottom) / (top - bottom), - near / (far - near), T1
    )
end

projection = ortho_projection(0f0, convert(Float32, RESOLUTION[1]), 0f0, convert(Float32, RESOLUTION[2]), -1f0, 0f0)

v_shader = GLA.Shader(GL_VERTEX_SHADER, read("shader_vertex.glsl"))
f_shader = GLA.Shader(GL_FRAGMENT_SHADER, read("shader_fragment.glsl"))
g_shader = GLA.Shader(GL_GEOMETRY_SHADER, read("shader_geom.glsl"))
shader_program = GLA.Program(v_shader, g_shader, f_shader)

texture = GLA.Texture(collect(snake_img'), minfilter=:nearest)

buffers = GLA.generate_buffers(shader_program, GLA.GEOMETRY_DIVISOR, pos_img = points)
vao = GLA.VertexArray(buffers, GL_POINTS)

GLA.bind(shader_program)
GLA.gluniform(shader_program, :projection, projection)
GLA.gluniform(shader_program, :sprite_size, convert(Float32, SPRITE_WIDTH))
GLA.gluniform(shader_program, :tex0, 0, texture)

glClearColor( 0.7, 0.7, 1, 0 )
glEnable(GL_BLEND)
glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)


GLFW.SetKeyCallback(window, (_, key, scancode, action, mods) -> begin
    if action == GLFW.PRESS
        g_keys[key] = true
    else
        g_keys[key] = false
    end
end)
