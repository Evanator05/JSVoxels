#version 300 es
precision highp float; // high floating point precision

out vec4 outputColor;

uniform vec4 screenSize; // width, height, 1/width, 1/height

void main() {
    vec2 UV = vec2(gl_FragCoord.x, gl_FragCoord.y)*screenSize.zw;
    outputColor = vec4(UV.x, UV.y, 1.0-UV.x, 1.0);
}