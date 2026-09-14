extern vec2 centerXY;
extern float radius;
extern float innerRadius;


vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    // Get the original texture color
    vec4 texcolor = Texel(tex, texture_coords);
    
    float alpha = 1.0;
    
    float dist = distance(screen_coords, centerXY);
    if(dist <= radius) {
        alpha = 0.0; // Fully transparent inside the circle and outside innerRadius
    }

    if(dist >= innerRadius){
        // Apply the alpha value to the texture
        return vec4(texcolor.rgb, texcolor.a * alpha);
    }

    // inside innerRadius. not using texture because it looks strange as it does not connect to outer space and it looks like random triangle. change to transparent dark color instead
    alpha = smoothstep(innerRadius-10.0,innerRadius,dist)*0.3+0.3;
    return vec4(0,0,0,alpha);
}