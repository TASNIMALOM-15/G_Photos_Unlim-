#version 100

attribute vec4 aFramePosition;
varying vec2 vTexSamplingCoord;

void main() {
    gl_Position = aFramePosition;
    vec4 texturePosition = vec4(aFramePosition.x * 0.5 + 0.5, aFramePosition.y * 0.5 + 0.5, 0.0, 1.0);
    vTexSamplingCoord = (texturePosition).xy;
}