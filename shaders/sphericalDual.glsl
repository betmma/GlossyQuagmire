// Sprites are already projected in camera space into separated source circles.
// Source and foreground circles have identical radii: only crop and translate.
extern vec2 source_primary_center;
extern vec2 source_secondary_center;
extern vec2 main_center;
extern float main_radius;
extern vec2 mini_center;
extern float mini_radius;
extern vec2 canvas_size;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 dMain = screen_coords - main_center;
    vec2 dMini = screen_coords - mini_center;
    vec2 sourcePixel;

    if (dot(dMain, dMain) <= main_radius * main_radius) {
        sourcePixel = source_primary_center + dMain;
    } else if (dot(dMini, dMini) <= mini_radius * mini_radius) {
        sourcePixel = source_secondary_center + dMini;
    } else {
        return vec4(0.0);
    }

    return Texel(tex, sourcePixel / canvas_size) * color;
}
