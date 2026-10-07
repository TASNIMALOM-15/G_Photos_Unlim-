// Crop frame fragment shader. Draws overlay on top of photo.

precision highp float;

// Coordinates of the pixel on the image.
varying vec2 v_ScreenCoordinates;
uniform sampler2D u_BaseTextureUnit;
uniform vec2 texel_size0;

// Bounds of the canvas in pixel coordinates.
uniform vec4 u_CanvasRectPx;

// Left top corner of crop frame.
uniform vec2 u_LeftTopCorner;

// Right bottom corner of crop frame.
uniform vec2 u_RightBottomCorner;

// Width of the crop handle.
uniform float u_HandleWidth;

// Radius of the crop handle arc.
uniform float u_HandleRadius;

// Length of the crop handle segment.
uniform float u_HandleLength;

// Offset of the crop handle from the image corner.
uniform float u_HandleOffset;

// Width of rule of thirds lines.
uniform float u_RuleOfThirdsWidth;

// Rule of thirds opacity.
uniform float u_RuleOfThirdsOpacity;

// Rule of thirds count of lines.
uniform float u_RuleOfThirdsCount;

// Radius of the rule of thirds corner.
uniform float u_RuleOfThirdsCornerRadius;

// Colors used for drawing crop frame.
uniform vec4 u_FogColor;

// Color used for the area outside the crop region but inside the canvas.
uniform vec4 u_CanvasFogColor;

// Color used for the border between the handles and the cropped area.
uniform vec4 u_BorderColor;

// Color used for the crop handles.
uniform vec4 u_CropHandlesColor;

// Color used for crop corners.
const vec4 kCornerColor = vec4(1., 1., 1., 1.);

// Color used for rule of thirds lines.
const vec4 kRuleOfThirdsColor = vec4(.7, .7, .7, 1.0);

// Value used to check if boolean values passed as ints are true.
const float kTrue = 1.0;

const float kPi = 3.14159265359;

// Signed distance function for a rounded box.
float rounded_box_sdf(vec2 p, vec2 center, vec2 size, float radius) {
  return length(max(abs(p - center) - size + radius, 0.0)) - radius;
}

// Signed distance function for a grid. The grid is centered with an
// intersection on the origin and extends to infinity in all directions.
float grid_sdf(vec2 position, vec2 origin, vec2 pitch) {
  vec2 cell = fract((position - origin) / pitch);
  float dx = min(cell.x, 1.0 - cell.x) * pitch.x;
  float dy = min(cell.y, 1.0 - cell.y) * pitch.y;
  return min(dx, dy);
}

// Rotates a point counterclockwise by an angle in radians.
vec2 rotate(vec2 p, float angle) {
  float s = sin(angle);
  float c = cos(angle);
  return vec2(c * p.x - s * p.y, s * p.x + c * p.y);
}

// Signed distance function for a segment.
float segment_sdf(vec2 p, vec2 a, vec2 b) {
  vec2 ba = b - a;
  vec2 pa = p - a;
  float at = clamp(dot(pa, ba) / dot(ba, ba), 0., 1.);
  vec2 q = a + at * ba;
  return length(p - q);
}

// Signed distance function for an arc.
float arc_sdf(vec2 p, vec2 center, float radius, float start, float end) {
  // Translate and rotate the coordinate system to center the arc at the origin
  // and align its midpoint with the positive y-axis.
  start -= kPi/2.;
  end -= kPi/2.;
  p -= center;
  p = rotate(p, -(start + end) / 2.);

  // Apply y-axis symmetry to only consider positive x values.
  p.x = abs(p.x);

  // Calculate the signed distance based on whether the point is within the
  // arc's sector.
  float angle = abs(start - end);
  vec2 extremity = radius * vec2(sin(angle / 2.), cos(angle / 2.));
  return (extremity.y * p.x > extremity.x * p.y)
      ? length(p - extremity)
      : abs(length(p) - radius);
}

// Signed distance function for a crop handle. The handle is modeled as a
// quarter circle with extended segments on both sides.
float handle_sdf(vec2 p, vec2 center, float angle, float radius, float length) {
  // Translate and rotate the coordinate system to center the handle at the
  // origin and align its segments with the positive x and y-axis.
  p = rotate(p, -angle);
  center = rotate(center, -angle);

  // Calculate the signed distance to the arc and segments.
  float arc_distance = arc_sdf(
      p, vec2(center.x + radius, center.y + radius), radius, kPi, 3.*kPi/2.);
  float start_segment_distance = segment_sdf(p,
      vec2(center.x + radius, center.y),
      vec2(center.x + radius + length, center.y));
  float end_segment_distance = segment_sdf(p,
      vec2(center.x, center.y + radius),
      vec2(center.x, center.y + radius + length));

  // Calculate the distance to the union of the arc and segments.
  return min(arc_distance, min(start_segment_distance, end_segment_distance));
}

// Signed distance function for a set of crop handles. The set consists of one
// handle for each corner of the frame.
float handle_set_sdf(vec2 p, vec2 bottom_left, vec2 top_right, float offset,
                     float radius, float length) {
  // Calculate the signed distance to handle.
  float bottom_left_distance = handle_sdf(
      p, bottom_left - offset, 0., radius, length);
  float bottom_right_distance = handle_sdf(
      p, vec2(top_right.x + offset, bottom_left.y - offset), kPi / 2., radius,
      length);
  float top_right_distance = handle_sdf(
      p, top_right + offset, kPi, radius, length);
  float top_left_distance = handle_sdf(
      p, vec2(bottom_left.x - offset, top_right.y + offset), 3. * kPi / 2.,
      radius, length);

  // Return the signed distance to the union of the handles.
  return min(
      min(bottom_left_distance, bottom_right_distance),
      min(top_right_distance, top_left_distance));
}

// Renders an anti-aliased SDF shape by blending the input color onto the
// current fragment.
void draw_sdf(float distance, vec4 color, inout vec4 frag_color) {
  float alpha = clamp(.5 - distance, 0., 1.);
  frag_color = mix(frag_color, vec4(color.rgb, 1.), alpha * color.a);
}

void main() {
  vec2 p = v_ScreenCoordinates;
  vec2 bottom_left = vec2(u_LeftTopCorner.x, u_RightBottomCorner.y);
  vec2 top_right = vec2(u_RightBottomCorner.x, u_LeftTopCorner.y);
  vec4 shade = vec4(0.);

  // Draw the fog.
  float box_distance = rounded_box_sdf(
      p, (bottom_left + top_right) / 2., (top_right - bottom_left) / 2.,
      u_RuleOfThirdsCornerRadius);
  float canvas_distance = rounded_box_sdf(p,
      (u_CanvasRectPx.xy + u_CanvasRectPx.zw) / 2.,
      (u_CanvasRectPx.zw - u_CanvasRectPx.xy) / 2.,
      u_RuleOfThirdsCornerRadius);
  vec4 fog_color = (canvas_distance <= 0.) ? u_CanvasFogColor : u_FogColor;
  draw_sdf(-box_distance + .5, fog_color, shade);

  // Draw the rule of thirds lines.
  float grid_distance = grid_sdf(
      p, bottom_left, (top_right - bottom_left) / u_RuleOfThirdsCount);
  float masked_grid_distance = max(
      grid_distance - u_RuleOfThirdsWidth,
      box_distance + u_RuleOfThirdsWidth + 1.);
  draw_sdf(masked_grid_distance,
      vec4(kRuleOfThirdsColor.rgb, u_RuleOfThirdsOpacity), shade);

  // Draw the border between the handles and the cropped area.
  float border_width = u_HandleOffset - u_HandleWidth / 2.;
  float border_distance = abs(box_distance - border_width / 2.);
  draw_sdf(border_distance - border_width / 2., u_BorderColor, shade);

  // Draw the handles.
  float handle_distance = handle_set_sdf(p, bottom_left,
      top_right, u_HandleOffset, u_HandleRadius, u_HandleLength);
  draw_sdf(handle_distance - u_HandleWidth / 2., u_CropHandlesColor, shade);

  gl_FragColor = shade;
}
