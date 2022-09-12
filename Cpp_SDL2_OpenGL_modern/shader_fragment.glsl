#version 330 core

in vec2 UV;
//out vec4 color;
out vec3 color;

uniform sampler2D tex0;

void main(){

    //color = texture( tex0, UV ).rgba;
    color.r = 1;
    color.g = 0;
    color.b = 0;
}
