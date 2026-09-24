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

// Hyperboloid coordinates use the metric x*x + y*y - z*z.
// A regular {4,6} tile has 60-degree corners and Klein edges at +/-1/sqrt(3).
const float TILE_HALF_EXTENT = 0.5773502691896258;
const float EDGE_SPACE = 1.224744871391589;
const float EDGE_TIME = 0.7071067811865476;
// Two reflections across opposite sides translate by four times the inradius.
// The textured tiling repeats exactly after this distance.
const float SCROLL_PERIOD = 2.633915793849633;

float lorentzDot(vec3 a, vec3 b) {
    return dot(a.xy,b.xy)-a.z*b.z;
}

vec3 fromUHP(vec2 point) {
    vec2 p=(point-screenCenter)/(screenCenter.y-shape_axis_y);
    p.y+=1.0;
    float square=dot(p,p);
    return vec3(2.0*p.x,square-1.0,square+1.0)/(2.0*p.y);
}

// Inverse translation: sample the stationary tiling behind a moving layer.
// There is no accumulated camera state; viewDirection is a rotation only.
vec3 scrollPoint(vec3 point, float direction, float distance) {
    vec2 axis=vec2(cos(direction),sin(direction));
    vec2 localPoint=vec2(dot(point.xy,axis),dot(point.xy,vec2(-axis.y,axis.x)));
    // Wrap an exact tiling symmetry so long spells retain floating-point precision.
    // Rotation is applied to the entire layer, independently of elapsed time.
    float travel=mod(distance+0.5*SCROLL_PERIOD,SCROLL_PERIOD)-0.5*SCROLL_PERIOD;
    float e=exp(travel);
    float c=0.5*(e+1.0/e);
    float s=0.5*(e-1.0/e);
    return vec3(c*localPoint.x-s*point.z,localPoint.y,
                c*point.z-s*localPoint.x);
}

vec2 tileUV(vec3 point) {
    // Reflect across actual hyperbolic geodesics, not a warped Euclidean grid.
    // Choosing the most violated side folds any tile back into the central square.
    for (int i=0; i<96; ++i) {
        vec3 normal;
        if (abs(point.x)>abs(point.y)) {
            normal=vec3(sign(point.x)*EDGE_SPACE,0.0,EDGE_TIME);
        } else {
            normal=vec3(0.0,sign(point.y)*EDGE_SPACE,EDGE_TIME);
        }
        float side=lorentzDot(point,normal);
        if (side<=0.000001) break;
        point-=2.0*side*normal;
    }
    vec2 klein=point.xy/point.z;
    return clamp(klein/(2.0*TILE_HALF_EXTENT)+0.5,0.0,1.0);
}

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
