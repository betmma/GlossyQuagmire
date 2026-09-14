// Bake the original value-noise hash at integer lattice points. 128 z slices
// occupy a 16 x 8 atlas, each 128 x 128. Every axis covers [-32,95].
// This covers all noise octaves used by stage5S2R.glsl, including +1 corners.
float hash31(vec3 p) {
    p = fract(p*0.1031);
    p += dot(p, p.yzx + 33.33);
    return fract((p.x + p.y)*p.z);
}

vec4 effect(vec4 color, Image texture, vec2 textureCoords, vec2 screenCoords) {
    vec2 pixel = floor(screenCoords);
    vec2 tile = floor(pixel/128.0);
    vec3 cell = vec3(mod(pixel, 128.0), tile.x+tile.y*16.0)-32.0;
    return vec4(hash31(cell), 0.0, 0.0, 1.0);
}
