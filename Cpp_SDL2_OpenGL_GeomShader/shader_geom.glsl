#version 330 core

layout (points) in;
layout (triangle_strip, max_vertices = 4) out;

out vec2 UV;

uniform mat4 projection;
uniform float sprite_size;

void main() {
    vec4 p = vec4(gl_in[0].gl_Position.xy, 0.0f, 1.0f);
    int img_linidx = int(gl_in[0].gl_Position.z);
    int img_row = img_linidx / 4;
    int img_col = img_linidx - img_row*4;
    vec2 t = vec2(float(img_col), float(img_row)) * 0.25f;

    gl_Position = projection * p;
    UV = t+vec2(0.0f, 0.25f);
    EmitVertex();
    gl_Position = projection * (p+vec4(sprite_size, 0.0f, 0.0f, 0.0f));
    UV = t+vec2(0.25f, 0.25f);
    EmitVertex();
    gl_Position = projection * (p+vec4(0.0f, sprite_size, 0.0f, 0.0f));
    UV = t+vec2(0.0f, 0.0f);
    EmitVertex();
    gl_Position = projection * (p+vec4(sprite_size, sprite_size, 0.0f, 0.0f));
    UV = t+vec2(0.25f, 0.0f);
    EmitVertex();
}

