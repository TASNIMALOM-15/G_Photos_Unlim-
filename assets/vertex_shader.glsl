#version 100
attribute vec4 aFramePosition;
attribute mediump vec4 aTexCoords;
varying mediump vec3 vTexSamplingCoord;
uniform mat4 uHomographyMatrix;
uniform mat4 uTexCoordMatrix;

void main() {
  gl_Position = aFramePosition;

  // TODO: b/401308268 - Add more detailed documentation here for the equation.
  // See associated StabilizeGlShaderProgram.kt for more details on the
  // transformation matrix ordering.
  vTexSamplingCoord = (uTexCoordMatrix * uHomographyMatrix * aTexCoords).xyw;
}
