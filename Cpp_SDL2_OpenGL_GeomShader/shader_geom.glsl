#version 330 core

layout (points) in;
layout (triangle_strip, max_vertices = 4) out;

uniform mat4 projection;
uniform float sprite_size;

void main() {
    //gl_Position = projection * vec4( pos_uv.xy, 0.0, 1.0 );
    //UV = pos_uv.zw;

    vec2 p = gl_in[0].xy;
    int img_linidx = int(gl_in[0].z);
    int img_row = img_linidx / 4;
    int img_col = img_linidx - img_row*4;
    vec2 t = vec2(float(img_col), float(img_row)) * 0.25f;

    gl_Position = vec4((projection * vec4(p, 0.0f, 1.0f)).xy, t.uv);
    EmitVertex();
    gl_Position = vec4((projection * vec4(p+vec2(sprite_size, 0.0f), 0.0f, 1.0f)).xy, t+vec2(0.25f, 0.0f));
    EmitVertex();
    gl_Position = vec4((projection * vec4(p+vec2(0.0f, sprite_size), 0.0f, 1.0f)).xy, t+vec2(0.0f, 0.25f));
    EmitVertex();
    gl_Position = vec4((projection * vec4(p+vec2(sprite_size, sprite_size), 0.0f, 1.0f)).xy, t+vec2(0.25f, 0.25f));
    EmitVertex();
}
