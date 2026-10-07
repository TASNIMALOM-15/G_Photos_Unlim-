precision highp float;
varying mediump vec2 sample_coordinate;
uniform sampler2D u_BaseTextureUnit;
uniform sampler2D u_TextureLookupTable;
uniform float u_LookIndex;
uniform float u_LooksCount;
uniform float u_LookIntensity;
uniform float u_LookIsGrayscale;
const float kLookupSize = 17.0;

vec3 ApplyLookup(vec3 color,
                 sampler2D lookup_table,
                 float lut_index,
                 float is_grayscale,
                 float luts_count,
                 float intensity) {
  vec3 clamped = clamp(color, vec3(0.0), vec3(1.0));

  float blue_coord = (kLookupSize - 1.0) * clamped.b;
  float blue_coord_low = clamp(floor(blue_coord), 0.0, kLookupSize - 2.0);

  float lower_y =
      (0.5 + blue_coord_low * kLookupSize + clamped.g * (kLookupSize - 1.0)) /
      (kLookupSize * kLookupSize);
  float upper_y = lower_y + 1.0 / kLookupSize;

  float x = 0.5 + kLookupSize * lut_index + clamped.r * (kLookupSize - 1.0);

  // Every LUT consists of two.
  x = (x + kLookupSize * lut_index) / 2.0;

  x /= kLookupSize * luts_count;
  vec3 lower_rgb = texture2D(lookup_table, vec2(x, lower_y)).rgb;
  vec3 upper_rgb = texture2D(lookup_table, vec2(x, upper_y)).rgb;
  float frac_b = blue_coord - blue_coord_low;
  if (intensity > 0.5) {
    // Take second LUT into account.
    float offset = kLookupSize / (2.0 * kLookupSize * luts_count);
    vec3 lower_rgb2 = texture2D(lookup_table, vec2(x + offset, lower_y)).rgb;
    vec3 upper_rgb2 = texture2D(lookup_table, vec2(x + offset, upper_y)).rgb;
    color = mix(lower_rgb2, upper_rgb2, frac_b);
  } else if (is_grayscale > 0.5) {
    color = vec3(0.3 * color.r + 0.59 * color.g + 0.11 * color.b);
  }
  // 0.0 is the first LUT.
  // 1.0 is either original color or the second LUT.
  intensity = 1.0 - abs(intensity - 0.5) * 2.0;
  return mix(color, mix(lower_rgb, upper_rgb, frac_b), intensity);
}

void main() {
  vec4 base_color =
        texture2D(u_BaseTextureUnit, sample_coordinate);
  vec3 color = ApplyLookup(base_color.rgb,
                             u_TextureLookupTable,
                             u_LookIndex,
                             u_LookIsGrayscale,
                             u_LooksCount,
                             u_LookIntensity);
  // We need to use pre-multiplied alpha.
  gl_FragColor = vec4(color * base_color.a, base_color.a);
}
