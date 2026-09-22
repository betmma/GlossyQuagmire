extern vec2 centerXY;
extern float radius;
extern vec2 centerXY2;
extern float radius2;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    // Get the original texture color
    vec4 texcolor = Texel(tex, texture_coords);
    
    float alpha = 1.0;
    float white = 0.0;
    vec3 whiteColor=vec3(1.0,1.0,1.0);
    float edge=10.0;
    
    float dist = distance(screen_coords, centerXY);
    if(dist <= radius) {
        alpha = 0.0; // Fully transparent inside the circle
    }else if(dist <= radius+edge){
        white=1.0-smoothstep(0,edge,dist-radius);
    }

    float dist2 = distance(screen_coords, centerXY2);
    if(dist2 <= radius2) {
        alpha = 0.0; // Fully transparent inside the second circle
    }else if(dist2 <= radius2+edge){
        white=1.0-smoothstep(0,edge,dist2-radius2);
    }
    white=white*0.5;
    
    // Apply the alpha value and the white edge to the texture
    vec3 finalColor = mix(texcolor.rgb, whiteColor, white);
    return vec4(finalColor, texcolor.a * alpha);
}