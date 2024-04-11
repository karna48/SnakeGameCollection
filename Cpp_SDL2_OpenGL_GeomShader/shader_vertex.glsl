#version 330 core

layout(location = 0) in vec3 pos_img;

void main() {
    gl_Position = vec4( pos_img.xyz, 1.0 );
}
