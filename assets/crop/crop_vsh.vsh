// Photo vertex shader. It transform vertex and texture coordinates with respect
// to rotate and scale operations.
attribute vec4 position;

// Texture coordinates for given vertex.
attribute vec4 texture_coordinate;

// Transformation for vertex coordinates.
uniform mat3 u_VertexTransform;

// Final transformation to convert to buffer coordinates.
uniform mat3 u_ScreenToBufferTransform;

// Transformation for texture coordinates.
uniform mat3 u_TextureTransform;

// Transformation corresponding to texture prespective projection.
uniform mat3 u_TexturePerspectiveWarp;

// Output texture coordinates.
varying vec3 v_TextureCoordinates;

// Coordinates of this vertex in surface coordinates.
varying vec3 v_Position;

void main() {
  v_TextureCoordinates = u_TextureTransform * vec3(texture_coordinate.xy, 1.);

  // Apply homography after transfering from clip coordinate space because the
  // perspective transformation matrix is calculated using texture coordinates.
  v_TextureCoordinates = u_TexturePerspectiveWarp * v_TextureCoordinates;

  // Apply vertex transformation.
  vec3 position_v3 = vec3(position.xy, 1.);
  v_Position = u_VertexTransform * position_v3;

  vec3 buffer_position = u_ScreenToBufferTransform * v_Position;
  // Make sure that we didn't change z and w.
  gl_Position = vec4(buffer_position.xy, 1., 1.);
}