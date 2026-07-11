uniform vec2 pos1s[4];
uniform vec2 pos2s[4];
uniform vec2 posIns[4];
uniform int numMirrors;
uniform float transparency;
uniform vec3 hsv;
uniform float dh;

float sideOfLine(vec2 point, vec2 lineStart, vec2 lineEnd) {
    vec2 line = lineEnd - lineStart;
    vec2 offset = point - lineStart;
    return line.x * offset.y - line.y * offset.x;
}

vec2 reflectAcrossLine(vec2 point, vec2 lineStart, vec2 lineEnd) {
    vec2 line = lineEnd - lineStart;
    float lineLengthSquared = dot(line, line);
    float projection = dot(point - lineStart, line) / lineLengthSquared;
    vec2 foot = lineStart + line * projection;
    return foot * 2.0 - point;
}

vec3 foldInsideMirrors(vec2 point) {
    float reflectionCount = 0.0;

    for(int iteration=0; iteration<32; iteration++) {
        bool reflected = false;

        for(int mirrorIndex=0; mirrorIndex<4; mirrorIndex++) {
            if (mirrorIndex >= numMirrors) break; // Only process the actual number of mirrors. WebGL compatibility requires a fixed loop count.
            vec2 line = pos2s[mirrorIndex] - pos1s[mirrorIndex];
            float lineLengthSquared = dot(line, line);

            if(lineLengthSquared > 0.000001) {
                float insideSide = sideOfLine(posIns[mirrorIndex], pos1s[mirrorIndex], pos2s[mirrorIndex]);
                float pointSide = sideOfLine(point, pos1s[mirrorIndex], pos2s[mirrorIndex]);

                if(abs(insideSide) > 0.000001 && insideSide * pointSide < 0.0) {
                    point = reflectAcrossLine(point, pos1s[mirrorIndex], pos2s[mirrorIndex]);
                    reflectionCount += 1.0;
                    reflected = true;
                    break;
                }
            }
        }

        if(!reflected) {
            break;
        }
    }

    return vec3(point, reflectionCount);
}

vec3 hsvToRgb(vec3 hsvColor) {
    float hueSector = mod(hsvColor.x, 1.0) * 6.0;
    float chroma = hsvColor.z * hsvColor.y;
    float secondary = chroma * (1.0 - abs(mod(hueSector, 2.0) - 1.0));
    vec3 rgb;

    if(hueSector < 1.0) {
        rgb = vec3(chroma, secondary, 0.0);
    }else if(hueSector < 2.0) {
        rgb = vec3(secondary, chroma, 0.0);
    }else if(hueSector < 3.0) {
        rgb = vec3(0.0, chroma, secondary);
    }else if(hueSector < 4.0) {
        rgb = vec3(0.0, secondary, chroma);
    }else if(hueSector < 5.0) {
        rgb = vec3(secondary, 0.0, chroma);
    }else{
        rgb = vec3(chroma, 0.0, secondary);
    }

    float minimum = hsvColor.z - chroma;
    return rgb + vec3(minimum);
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec3 folded = foldInsideMirrors(screen_coords);
    vec2 foldedPosition = folded.xy;
    float reflectionCount = folded.z;
    vec2 foldedTextureCoords = foldedPosition / love_ScreenSize.xy;

    vec4 originalColor = Texel(tex, texture_coords) * color;
    vec4 reflectedColor = Texel(tex, foldedTextureCoords) * color;
    if(reflectionCount > 0.0) {
        float reflectedHue = mod(hsv.x + dh * reflectionCount, 1.0);
        reflectedColor.rgb *= hsvToRgb(vec3(reflectedHue, hsv.y, hsv.z));
    }
    float reflectionOpacity = clamp(transparency, 0.0, 1.0);

    return mix(originalColor, reflectedColor, reflectionOpacity);
}
