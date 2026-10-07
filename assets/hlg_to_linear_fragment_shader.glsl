precision mediump float;

uniform sampler2D uTexSampler;
varying vec2 vTexSamplingCoord;

// HLG EOTF constants (same as OETF)
const float a = 0.17883277;
const float b = 0.28466892;
const float c = 0.55991073;

// HLG Electro-Optical Transfer Function (EOTF)
// This is the inverse of the HLG OETF.
// V is the HLG encoded value.
float hlg_eotf(float V) {
  if (V <= 0.5) {
    // Inverse of V = sqrt(3.0 * L) => L = V^2 / 3.0
    return V * V / 3.0;
  } else {
    // Inverse of V = a * log(12.0 * L - b) + c => L = (exp((V - c) / a) + b) / 12.0
    return (exp((V - c) / a) + b) / 12.0;
  }
}

void main() {
  // Sample the HLG encoded color from the texture
  vec4 hlgColor = texture2D(uTexSampler, vTexSamplingCoord);

  // Apply HLG EOTF to each color channel.
  float r = hlg_eotf(hlgColor.r);
  float g = hlg_eotf(hlgColor.g);
  float b = hlg_eotf(hlgColor.b);

  // Output the linear color
  gl_FragColor = vec4(r, g, b, hlgColor.a);
}
