#version 330 core

in vec2 UV;
//out vec4 color;
out vec4 color;

uniform sampler2D tex0;

void main(){

    color = texture( tex0, UV ).rgba;
}
