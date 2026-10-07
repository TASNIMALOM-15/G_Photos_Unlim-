// Letterbox fragment shader.
// Set to transparent if outside of the margin rect, set to opaque otherwise.

precision highp float;

uniform sampler2D texture0;
varying mediump vec2 sample_coordinate;

// Margins
uniform float u_MarginLeft;
uniform float u_MarginRight;
uniform float u_MarginTop;
uniform float u_MarginBottom;

void main() {
  // TODO: b/485727295 - Modifying the alpha channel does not appear to work as
  // expected.
  vec4 pixel0 = texture2D(texture0, sample_coordinate);
  if (sample_coordinate.x < u_MarginLeft
      || sample_coordinate.x > u_MarginRight
      || sample_coordinate.y < u_MarginTop
      || sample_coordinate.y > u_MarginBottom) {
    pixel0.a = 0.0;
  } else {
    pixel0.a = 1.0;
  }
  gl_FragColor = pixel0;
}