precision highp float;
varying mediump vec2 sample_coordinate;
uniform sampler2D u_BaseTextureUnit;
uniform sampler2D u_TextureLookupTable;

const float kLookupSize = 17.0;

vec3 ApplyLookup(vec3 color,
                 sampler2D lookup_table) {
  vec3 clamped = clamp(color, vec3(0.0), vec3(1.0));

  float blue_coord = (kLookupSize - 1.0) * clamped.b;
  float blue_coord_low = clamp(floor(blue_coord), 0.0, kLookupSize - 2.0);

  float lower_y =
      (0.5 + blue_coord_low * kLookupSize + clamped.g * (kLookupSize - 1.0)) /
      (kLookupSize * kLookupSize);
  float upper_y = lower_y + 1.0 / kLookupSize;

  float x = 0.5 + clamped.r * (kLookupSize - 1.0);
  x /= kLookupSize;
  vec3 lower_rgb = texture2D(lookup_table, vec2(x, lower_y)).rgb;
  vec3 upper_rgb = texture2D(lookup_table, vec2(x, upper_y)).rgb;
  float frac_b = blue_coord - blue_coord_low;
  return mix(color, mix(lower_rgb, upper_rgb, frac_b), 1.0);
}

void main() {
  vec3 base_color =
        texture2D(u_BaseTextureUnit, sample_coordinate).rgb;
  vec3 color = ApplyLookup(base_color,
                          u_TextureLookupTable);
  gl_FragColor = vec4(color, 1);
}
