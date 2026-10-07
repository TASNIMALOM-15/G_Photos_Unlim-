precision mediump float;
varying mediump vec3 vTexSamplingCoord;
uniform sampler2D uTexSampler;

void main() {
  vec2 texcoord = vTexSamplingCoord.xy / vTexSamplingCoord.z;
  gl_FragColor = texture2D(uTexSampler, texcoord);
}
