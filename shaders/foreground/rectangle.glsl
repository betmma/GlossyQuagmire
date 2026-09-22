extern vec4 xywh;


vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    // Get the original texture color
    vec4 texcolor = Texel(tex, texture_coords);
    
    float alpha = 1.0;
    float white = 0.0;
    vec3 whiteColor=vec3(1.0,1.0,1.0);
    float edge=10.0;
    
    if(xywh.x <= screen_coords.x && screen_coords.x <= xywh.x+xywh.z &&
       xywh.y <= screen_coords.y && screen_coords.y <= xywh.y+xywh.w) {
        alpha = 0.0; // Fully transparent inside the rectangle
    }
    float dist=9990.0;
    if(xywh.x <= screen_coords.x && screen_coords.x <= xywh.x+xywh.z) {
        dist=min(dist,abs(screen_coords.y-xywh.y));
        dist=min(dist,abs(screen_coords.y-(xywh.y+xywh.w)));
    }
    if(xywh.y <= screen_coords.y && screen_coords.y <= xywh.y+xywh.w) {
        dist=min(dist,abs(screen_coords.x-xywh.x));
        dist=min(dist,abs(screen_coords.x-(xywh.x+xywh.z)));
    }
    dist=min(dist,distance(screen_coords,xywh.xy));
    dist=min(dist,distance(screen_coords,xywh.xy+vec2(xywh.z,0.0)));
    dist=min(dist,distance(screen_coords,xywh.xy+vec2(0.0,xywh.w)));
    dist=min(dist,distance(screen_coords,xywh.xy+vec2(xywh.z,xywh.w)));
    if(dist <= edge) {
        white=1.0-smoothstep(0,edge,dist);
        white=white*0.5;
    }

    // Apply the alpha value and the white edge to the texture
    vec3 finalColor = mix(texcolor.rgb, whiteColor, white);
    return vec4(finalColor, texcolor.a * alpha);
}