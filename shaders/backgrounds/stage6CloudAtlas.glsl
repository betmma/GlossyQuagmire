#include "shaders/backgrounds/stage6CloudField.glsl"

vec4 effect(vec4 color,Image texture,vec2 texture_coords,vec2 screen_coords) {
    // Texel centers match the periodic bilinear lookup in stage6S3.glsl.
    vec2 angles=(screen_coords/vec2(4096.0,1024.0)-0.5)*6.28318530718;
    return vec4(cloudField(angles.x,angles.y),0.0,0.0,1.0);
}
