extern float progress; // The progress of the transition (0.0 to 1.0)


vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    // Get the original texture color
    vec4 texcolor = Texel(tex, texture_coords);
    
    // Get normalized screen coordinates (0.0 to 1.0)
    vec2 uv = screen_coords / love_ScreenSize.xy;
    
    float gray = dot(texcolor.rgb, vec3(0.299, 0.587, 0.114)); // Convert to grayscale
    float alpha = 1.0-smoothstep(progress*1.1-0.1, progress*1.1, gray+uv.y*0.5-0.5); // Transition based on grayscale value and progress
    
    // Apply the alpha value to the texture
    return vec4(texcolor.rgb, texcolor.a * alpha);
}