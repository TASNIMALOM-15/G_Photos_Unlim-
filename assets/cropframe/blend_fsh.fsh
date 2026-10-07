// Blend fragment shader. Blends two textures, using the alpha channel of the
// first texture.

precision highp float;

uniform sampler2D texture0;
uniform sampler2D texture1;
varying mediump vec2 sample_coordinate;

void main() {
  vec4 pixel0 = texture2D(texture0, sample_coordinate);
  vec4 pixel1 = texture2D(texture1, sample_coordinate);
  vec4 blended = pixel1 * pixel1.a + pixel0 * (1.0 - pixel1.a);
  gl_FragColor = vec4(blended.rgb, 1.0);
}