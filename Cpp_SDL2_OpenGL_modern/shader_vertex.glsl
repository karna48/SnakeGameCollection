#version 330 core

layout(location = 0) in vec4 pos_uv;
out vec2 UV;

uniform mat4 projection;

void main() {
    gl_Position = projection * vec4( pos_uv.xy, 0.0, 1.0 );
    UV = pos_uv.zw;
}
