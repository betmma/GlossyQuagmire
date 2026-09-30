#include "shaders/modelsTrans.glsl"

uniform Image baseTexture;
uniform Image overlayTexture;
uniform vec2 baseSize;
uniform vec2 overlaySize;
uniform vec2 spinSpeeds;
uniform float time;
uniform bool hyperbolicOverlay;
uniform float scrollDirection;
uniform float scrollSpeed;
uniform float viewDirection;
uniform vec2 screenCenter;
uniform float shape_axis_y;
uniform int hyperbolic_model;
uniform float r_factor;

#include "shaders/backgrounds/spellTessellation.glsl"

vec2 flatUV(vec2 point, vec2 size, float angle) {
    vec2 offset=point-screenCenter;
    float c=cos(angle),s=sin(angle);
    return vec2(c*offset.x+s*offset.y,-s*offset.x+c*offset.y)/size+0.5;
}

bool insideImage(vec2 uv) {
    return all(greaterThanEqual(uv,vec2(0.0))) && all(lessThanEqual(uv,vec2(1.0)));
}

vec4 effect(vec4 color, Image texture, vec2 textureCoords, vec2 screenCoords) {
    vec2 baseUV=flatUV(screenCoords,baseSize,spinSpeeds.x*time);
    if (!insideImage(baseUV)) return vec4(0.0);
    vec4 base=Texel(baseTexture,baseUV);
    vec4 overlay=vec4(1.0,1.0,1.0,0.0);
    if (hyperbolicOverlay) {
        bool inDomain;
        if (hyperbolic_model==HYPERBOLIC_MODEL_UHP) {
            inDomain=screenCoords.y>shape_axis_y;
        } else {
            float radius=0.5*min(love_ScreenSize.x,love_ScreenSize.y)*r_factor;
            vec2 disk=(screenCoords-screenCenter)/radius;
            inDomain=dot(disk,disk)<1.0;
        }
        if (inDomain) {
            vec2 uhp=ConvertFromOtherModel(screenCoords,screenCenter,shape_axis_y,
                                         r_factor,hyperbolic_model);
            vec2 uv=tileUV(scrollPoint(fromUHP(uhp),scrollDirection+viewDirection,
                                      scrollSpeed*time));
            overlay=Texel(overlayTexture,uv);
        }
    } else {
        vec2 uv=flatUV(screenCoords,overlaySize,spinSpeeds.y*time);
        if (insideImage(uv)) overlay=Texel(overlayTexture,uv);
    }
    // Transparent overlay pixels leave the base unchanged; opaque pixels multiply RGB.
    // Apply the spell fade once, after composing both layers.
    return vec4(base.rgb*mix(vec3(1.0),overlay.rgb,overlay.a),base.a)*color;
}
