precision highp float;
varying mediump vec2 sample_coordinate;
uniform sampler2D texture;
uniform vec2 texel_size0;

uniform float vignette_strength;
uniform float vignette_center_x;
uniform float vignette_center_y;


vec3 RgbToYCbCr(vec3 color) {
  mat3 coeff = mat3(0.299,  0.587, 0.114,
                    -0.169, -0.331, 0.500,
                    0.500, -0.419, -0.081);
  vec3 result = color * coeff;
  return result + vec3(0.0, 0.5, 0.5);
}

vec3 YCbCrToRgb(vec3 color) {
  vec3 result = color + vec3(0.0, -0.5, -0.5);
  mat3 coeff = mat3(1.0, 0.000927, 1.402,
                    1.0, -0.344,   -0.714,
                    1.0, 1.772,    0.00099);
  result = result * coeff;
  return clamp(result, 0.0, 1.0);
}

float ComputeVignetteMask() {
  float kVignetteDiameter = exp(-4.0 * abs(vignette_strength)) + 0.5;
  float kVignetteDiameterScalingFactor = 0.5;
  float diameter_scaled =
      kVignetteDiameterScalingFactor * kVignetteDiameter;
  float diameter_safe = max(diameter_scaled, 0.0001);
  float blend = (exp(5.0 * diameter_scaled - 3.0) + 1.25) /
      (diameter_safe * sqrt(2.0));

  vec2 delta = vec2((sample_coordinate.x - vignette_center_x) * texel_size0.x,
                    (sample_coordinate.y - vignette_center_y) * texel_size0.y);
  float scale = 2.0 / (length(texel_size0) * diameter_safe);
  float blend_scaled = (blend + 1.0) / scale;
  float scaled_blend = scale / blend;
  float blended = clamp((blend_scaled - length(delta)) * scaled_blend,
                        0.0, 1.0);
  float smoothed = blended * blended * (3.0 - 2.0 * blended);
  return smoothed * smoothed;
  // return 1.0;
}

void main() {
  float kSaturationFactor = 0.3;
  vec3 color = texture2D(texture, sample_coordinate).rgb;

  vec3 ycbcr = RgbToYCbCr(color);
  vec3 ycbcr_adjusted = ycbcr;
  float vignette_mask = ComputeVignetteMask();
  ycbcr_adjusted.r = ycbcr.r * vignette_mask;
  ycbcr_adjusted.g = mix(
      ((ycbcr.g * 2.0 - 1.0) * vignette_mask + 1.0) / 2.0, ycbcr.g,
      kSaturationFactor);
  ycbcr_adjusted.b = mix(
      ((ycbcr.b * 2.0 - 1.0) * vignette_mask + 1.0) / 2.0, ycbcr.b,
      kSaturationFactor);

  vec3 rgb_adjusted = YCbCrToRgb(ycbcr_adjusted);
  gl_FragColor = vec4(rgb_adjusted, 1.0);
}
