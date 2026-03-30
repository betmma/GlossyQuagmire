extern vec4 xywh;


vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    // Get the original texture color
    vec4 texcolor = Texel(tex, texture_coords);
    
    float alpha = 1.0;
    
    if(xywh.x <= screen_coords.x && screen_coords.x <= xywh.x+xywh.z &&
       xywh.y <= screen_coords.y && screen_coords.y <= xywh.y+xywh.w) {
        alpha = 0.0; // Fully transparent inside the rectangle
    }

    // Apply the alpha value to the texture
    return vec4(texcolor.rgb, texcolor.a * alpha);
}