extern vec2 centerXY;
extern float radius;


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
        white=white*0.5;
    }

    vec3 finalColor = mix(texcolor.rgb,whiteColor,white);
    // Apply the alpha value to the texture
    return vec4(finalColor, texcolor.a * alpha);
}