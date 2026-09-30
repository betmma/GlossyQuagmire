#include "shaders/modelsTrans.glsl"

uniform Image textTexture;
uniform Image patternTexture;
uniform float time;
uniform float viewDirection;
uniform vec2 layerDirections;
uniform vec2 layerSpeeds;
uniform vec2 screenCenter;
uniform float shape_axis_y;
uniform int hyperbolic_model;
uniform float r_factor;

#include "shaders/backgrounds/spellTessellation.glsl"

vec4 effect(vec4 color, Image texture, vec2 textureCoords, vec2 screenCoords) {
    if (hyperbolic_model==HYPERBOLIC_MODEL_UHP) {
        if (screenCoords.y<=shape_axis_y) return vec4(0.0);
    } else {
        float radius=0.5*min(love_ScreenSize.x,love_ScreenSize.y)*r_factor;
        vec2 disk=(screenCoords-screenCenter)/radius;
        if (dot(disk,disk)>=1.0) return vec4(0.0);
    }

    vec2 uhp=ConvertFromOtherModel(screenCoords,screenCenter,shape_axis_y,
                                 r_factor,hyperbolic_model);
    vec3 point=fromUHP(uhp);
    vec2 textUV=tileUV(scrollPoint(point,layerDirections.x+viewDirection,
                                  layerSpeeds.x*time));
    vec2 patternUV=tileUV(scrollPoint(point,layerDirections.y+viewDirection,
                                     layerSpeeds.y*time));
    vec4 pattern=Texel(patternTexture,patternUV);
    vec4 text=Texel(textTexture,textUV);
    // Opaque base hides the stage when the boss manager's fade reaches one.
    vec3 base=mix(vec3(0.025,0.012,0.03),pattern.rgb,pattern.a);
    vec3 final=min(base+(vec3(1.0,1.0,1.0)-text.rgb)*text.a*0.2,1.0);
    return vec4(final,1.0)*color;
}
