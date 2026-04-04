extern vec2 centerXY;
extern float radius;
extern vec2 centerXY2;
extern float radius2;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    // Get the original texture color
    vec4 texcolor = Texel(tex, texture_coords);
    
    float alpha = 1.0;
    
    float dist = distance(screen_coords, centerXY);
    if(dist <= radius) {
        alpha = 0.0; // Fully transparent inside the circle
    }

    float dist2 = distance(screen_coords, centerXY2);
    if(dist2 <= radius2) {
        alpha = 0.0; // Fully transparent inside the second circle
    }
    
    // Apply the alpha value to the texture
    return vec4(texcolor.rgb, texcolor.a * alpha);
}