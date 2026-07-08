uniform float progress;
uniform vec2 screenCenter;

float saturate(float x) {
    return clamp(x, 0.0, 1.0);
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    float p = saturate(progress);
    vec4 base = Texel(tex, texture_coords) * color;

    float gray = dot(base.rgb, vec3(0.299, 0.587, 0.114));
    float grayscaleStrength = 1.0 - smoothstep(0.08, 1.0, p);
    float redStrength = 1.0 - smoothstep(0.08, 0.18, p);

    vec3 desaturated = mix(base.rgb, vec3(gray), grayscaleStrength);
    vec3 redShade = vec3(1.0, 0.38, 0.33);
    vec3 shaded = mix(desaturated, desaturated*redShade, redStrength);

    float vignette = distance((screen_coords.xy - screenCenter) / love_ScreenSize.xy, vec2(0.0));
    float edgeRed = smoothstep(0.18, 0.78, vignette) * redStrength;
    shaded += vec3(0.42, 0.0, 0.0) * edgeRed;

    return vec4(clamp(shaded, 0.0, 1.0), base.a);
}
