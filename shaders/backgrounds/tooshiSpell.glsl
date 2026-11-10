extern vec2 origin;
extern float referenceHeight;
extern float time;
extern float travel;

float hash(vec2 p) {
    vec3 q=fract(vec3(p.xyx)*0.1031);
    q+=dot(q,q.yzx+33.33);
    return fract((q.x+q.y)*q.z);
}

float noise(vec2 p) {
    vec2 cell=floor(p), f=fract(p);
    vec2 w=f*f*f*(f*(f*6.0-15.0)+10.0);
    return mix(mix(hash(cell),hash(cell+vec2(1,0)),w.x),
               mix(hash(cell+vec2(0,1)),hash(cell+vec2(1,1)),w.x),w.y);
}

float field(vec2 p) {
    mat2 turn=mat2(0.8,-0.6,0.6,0.8);
    float value=0.57*noise(p);
    p=turn*p*2.03+vec2(7.1,3.7);
    value+=0.28*noise(p);
    p=turn*p*2.01+vec2(2.8,9.2);
    return value+0.15*noise(p);
}

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 pixel) {
    float h=pixel.y-origin.y;
    if (h<=0.0) return vec4(0.012,0.002,0.003,1.0)*color;
    // Dilation about origin leaves x/h invariant and adds log(zoom) to v.
    // Inverse sampling makes recognizable folds follow the gameplay drag.
    vec2 p=vec2((pixel.x-origin.x)/h,log(h/referenceHeight)-travel)*2.5;
    float t=time*0.19;
    vec2 drift=vec2(0.12*t,0.36*t);
    vec2 q=vec2(field(p+drift),field(p+vec2(5.2,1.3)-drift*0.7));
    vec2 r=vec2(field(p+3.8*q+vec2(1.7,9.2)+vec2(0.0,t)),
                field(p+3.8*q+vec2(8.3,2.8)+vec2(-t*0.6,0.0)));
    float pigment=field(p+4.2*r);
    float phase=pigment*23.0+q.x*3.0;
    float vein=0.5+0.5*sin(phase);
    // Derivative filtering prevents the compressed upper veins from sparkling.
    float aa=max(fwidth(phase),0.001);
    float detail=1.0-smoothstep(0.6,3.0,aa);
    vein=mix(0.5,vein,detail);
    vec3 rgb=mix(vec3(0.018,0.003,0.005),vec3(0.29,0.025,0.008),
                 smoothstep(0.12,0.49,vein));
    rgb=mix(rgb,vec3(0.48,0.10,0.012),smoothstep(0.49,0.83,vein));
    float gold=smoothstep(0.87,0.96,vein)*detail;
    rgb=mix(rgb,vec3(0.58,0.29,0.045),gold);
    rgb*=0.75+0.25*pigment;
    float footprint=max(length(dFdx(p)),length(dFdy(p)));
    rgb=mix(rgb,vec3(0.13,0.025,0.008),smoothstep(0.025,0.16,footprint));
    return vec4(rgb,1.0)*color;
}
