// Identity vertex shader.
attribute vec4 position;

// Texture coordinates for given vertex.
attribute vec2 texture_coordinate;

// Size of the surface in pixels, used to scale texture coordinates.
uniform vec2 u_SurfaceSizePx;

// Transformation corresponding to screen rotation.
uniform mat3 u_ScreenRotation;

// Output screen coordinates.
varying vec2 v_ScreenCoordinates;

void main() {
  gl_Position = vec4(position.xy, 1., 1.);

  // We rotate screen coordinates.
  vec2 texture_coordinate_px = u_SurfaceSizePx * texture_coordinate;
  v_ScreenCoordinates = (u_ScreenRotation * vec3(texture_coordinate_px, 1.)).xy;
}