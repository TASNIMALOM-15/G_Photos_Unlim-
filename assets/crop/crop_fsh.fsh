// Photo fragment shader. It applies filters on texture.

precision highp float;

// Which texture unit to use.
uniform sampler2D u_BaseTextureUnit;

// Coordinates of the pixel on the image.
varying vec3 v_TextureCoordinates;
varying vec3 v_Position;

void main() {
  vec2 warped_texture_coordinates = v_TextureCoordinates.xy;
  if (v_TextureCoordinates.z != 0.0) {
    warped_texture_coordinates /= v_TextureCoordinates.z;
  }
  float alpha = 1.0;

  vec3 color =
        texture2D(u_BaseTextureUnit, warped_texture_coordinates).rgb;

 
  // This next clamp line shouldn't do anything, but it makes iPod Touches
  // work. Without it, iPod Touches display a black screen. We should
  // investigate why this is. It also cannot be moved into ApplyLookup.
  color = clamp(color, 0.0, 1.0);

  if (warped_texture_coordinates.x < 0. || warped_texture_coordinates.x > 1. ||
      warped_texture_coordinates.y < 0. || warped_texture_coordinates.y > 1.) {
    // Manually set an out of bounds pixel to black so we don't clamp to the
    // edge of the texture. We don't discard the pixel so that we can still show
    // the magnifier circle if necessary.
    color = vec3(0.);
  }

  gl_FragColor = vec4(color * alpha, alpha);
}