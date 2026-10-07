precision mediump float;

uniform sampler2D uTexSampler;
varying vec2 vTexSamplingCoord;

// HLG OETF constants
const float a = 0.17883277;
const float b = 0.28466892;
const float c = 0.55991073;

// HLG Opto-Electronic Transfer Function (OETF)
float hlg_oetf(float L) {
  if (L <= 1.0 / 12.0) {
    return sqrt(3.0 * L);
  } else {
    return a * log(12.0 * L - b) + c;
  }
}

void main() {
  // Sample the linear color from the texture
  vec4 linearColor = texture2D(uTexSampler, vTexSamplingCoord);

  // Apply HLG OETF to each color channel
  float r = hlg_oetf(linearColor.r);
  float g = hlg_oetf(linearColor.g);
  float b = hlg_oetf(linearColor.b);

  // Output the HLG encoded color
  gl_FragColor = vec4(r, g, b, linearColor.a);
}