uniform vec2 screenCenter;
uniform vec3 translation;
uniform float time;
uniform float pitch;
uniform float yaw;
uniform float roll;
uniform Image earth_texture;
uniform Image cloud_texture;
uniform Image moon_texture;
uniform Image cloud_field;
uniform bool use_cloud_field;

const float PI=3.14159265359;
const float TAU=6.28318530718;
// Unit S^3 embedded in R^4, with its round metric (sectional curvature +1).
// These sizes and orbit radius also enter the clearance proof in stage6S3.lua.
const float EARTH_RADIUS=0.19;
const float MOON_RADIUS=0.06;
const float ORBIT_RADIUS=0.60;
const float HIT_EPSILON=0.00015;
// Tilt the Earth/Moon system toward the camera's travel plane. This makes
// camera-to-Earth distance vary over a lap instead of remaining constant.
const float EARTH_TILT=1.20;
const vec4 EARTH=vec4(cos(EARTH_TILT),0.0,0.0,sin(EARTH_TILT));
const vec4 EARTH_POLE=vec4(-sin(EARTH_TILT),0.0,0.0,cos(EARTH_TILT));

vec4 earthFrame(vec4 p) {
    return p.x*EARTH+vec4(0.0,p.y,p.z,0.0)+p.w*EARTH_POLE;
}

float distanceS3(vec4 p,vec4 q) {
    return acos(clamp(dot(p,q),-1.0,1.0));
}

#include "shaders/backgrounds/stage6CloudField.glsl"

float cloudTubeRadius(vec4 p) {
    // Continuous tube around the great circle C0(t)=(0,0,sin(t),cos(t)).
    // max_t dot(p,C0(t))=length(p.zw): exact intrinsic distance to the trail.
    return acos(clamp(length(p.zw),0.0,1.0));
}

float spaceCloudDensity(vec4 p,float radius) {
    // Cirrus-like fibers occupy a thin wall. A thick noisy volume averages
    // away their fine contrast and looks like blurred fog instead of wisps.
    float envelope=smoothstep(0.245,0.259,radius)*(1.0-smoothstep(0.281,0.295,radius));
    if(envelope<=0.0) return 0.0;

    // Parallel-transported normals N1=(1,0,0,0), N2=(0,1,0,0).
    // Tube tangent T(t)=(0,0,cos(t),-sin(t)) rotates along the route.
    // Anisotropic noise uses fine transverse scales and long axial scales,
    // keeping the wisps stretched along LOCAL T, never a fixed ambient vec4.
    float theta=atan(p.y,p.x);
    float t=atan(p.z,p.w)+time*0.8;
    float field;
    if(use_cloud_field) {
        field=Texel(cloud_field,vec2(theta,t)/TAU+0.5).r;
    } else {
        field=cloudField(theta,t);
    }
    return envelope*field*24.0;
}

vec3 hsv2rgb(vec3 c) {
    vec3 p = abs(fract(c.xxx + vec3(0,2,1)/3.0)*6.0 - 3.0);
    return c.z * mix(vec3(1.0), clamp(p-1.0, 0.0, 1.0), c.y);
}

vec3 integrateSpaceClouds(vec4 camera,vec4 direction,float stop,vec3 behind) {
    vec3 scattered=vec3(0.0);
    float transmittance=1.0;
    // Distance to the trail is 1-Lipschitz, so empty regions can be skipped
    // conservatively. Fine steps inside the thin wall resolve individual fibers
    // without spending hundreds of uniform samples on empty space.
    float s=0.0;
    for(int i=0;i<512;i++) {
        if(s>=stop || transmittance<0.015) break;
        vec4 p=camera*cos(s)+direction*sin(s);
        float radius=cloudTubeRadius(p);
        float gap=max(0.245-radius,radius-0.295);
        if(gap>0.003) {
            s+=gap*0.95;
            continue;
        }
        float stepLength=min(0.006,stop-s);
        float midpoint=s+stepLength*0.5;
        p=camera*cos(midpoint)+direction*sin(midpoint);
        float density=spaceCloudDensity(p,cloudTubeRadius(p));
        if(density>0.0) {
            float opacity=1.0-exp(-density*stepLength);
            opacity=opacity*exp(-s*0.2);
            float illumination=0.60+0.25*dot(p,normalize(vec4(0.3,-0.5,-0.6,0.55)));
            vec3 tint=hsv2rgb(vec3((s+time*0.8)*0.15,0.2,0.7))*illumination;
            scattered+=transmittance*opacity*tint;
            transmittance*=1.0-opacity;
        }
        s+=stepLength;
    }
    return scattered+transmittance*behind;
}

vec2 sphereUV(vec3 n,float spin) {
    return vec2(atan(n.z,n.x)/TAU+0.5+spin,0.5-asin(clamp(n.y,-1.0,1.0))/PI);
}

vec3 surfaceColor(vec4 p,vec4 center,bool earth,float phase,vec4 towardCamera) {
    float radial=dot(p,center);
    // Inverse exponential-map direction at the body center. Geodesic sphere
    // surfaces have an S^2 of directions, giving ordinary lat/long texture UVs.
    vec4 u=normalize(p-radial*center);
    vec3 localDirection;
    if(earth) {
        localDirection=vec3(u.y,u.z,dot(u,EARTH_POLE));
    } else {
        // Orthonormal tangent frame transported from E along the lunar radius.
        vec4 radialAxis=earthFrame(vec4(-sin(ORBIT_RADIUS),cos(ORBIT_RADIUS)*cos(phase),
                            cos(ORBIT_RADIUS)*sin(phase),0.0));
        vec4 orbitAxis=vec4(0.0,-sin(phase),cos(phase),0.0);
        localDirection=vec3(dot(u,radialAxis),dot(u,EARTH_POLE),dot(u,orbitAxis));
    }
    // Both the outward normal and light direction live in T_p S^3.
    vec4 normal=normalize(radial*p-center);
    vec4 light=normalize(vec4(0.3,-0.5,-0.6,0.55));
    vec4 towardLight=normalize(light-dot(light,p)*p);
    float lightFacing=dot(normal,towardLight);
    float diffuse=max(lightFacing,0.0);
    vec3 albedo;
    if(earth) {
        vec2 uv=sphereUV(localDirection,time*0.012);
        albedo=Texel(earth_texture,uv).rgb;
        // The JPEG cloud map has no alpha: its luminance supplies coverage.
        vec3 clouds=Texel(cloud_texture,sphereUV(localDirection,time*0.014)).rgb;
        float coverage=dot(clouds,vec3(0.299,0.587,0.114));
        // Look slightly toward the light along the surface for elevated clouds
        // casting shadows here. Direction-space offsets stay smooth at UV seams.
        vec4 surfaceLight=towardLight-normal*lightFacing;
        vec3 localLight=vec3(surfaceLight.y,surfaceLight.z,dot(surfaceLight,EARTH_POLE));
        vec3 shadowDirection=normalize(localDirection+0.025*localLight);
        vec3 shadowClouds=Texel(cloud_texture,sphereUV(shadowDirection,time*0.014)).rgb;
        float shadowCoverage=dot(shadowClouds,vec3(0.299,0.587,0.114));
        albedo*=1.0-0.28*shadowCoverage*smoothstep(0.0,0.25,lightFacing);
        albedo=mix(albedo,vec3(0.94,0.97,1.0),coverage*0.88);
    } else {
        albedo=Texel(moon_texture,sphereUV(localDirection,0.0)).rgb;
    }
    vec3 shaded=albedo*(0.24+0.76*diffuse);
    if(earth) {
        // A thin atmospheric tint inside the silhouette, strongest in sunlight.
        float rim=pow(1.0-clamp(dot(normal,towardCamera),0.0,1.0),3.0);
        float sunlight=smoothstep(-0.15,0.6,lightFacing);
        shaded=mix(shaded,vec3(0.18,0.48,0.95),rim*sunlight*1.55);
    }
    return shaded;
}

vec4 effect(vec4 color,Image texture,vec2 texture_coords,vec2 screen_coords) {
    float a=translation.x,b=translation.y,t=translation.z;
    float ca=cos(a),sa=sin(a),cb=cos(b),sb=sin(b),ct=cos(t),st=sin(t);
    float u=sa,v=ca*sb,k=ca*cb;
    vec4 origin=vec4(u,v,0.0,k);
    vec4 initialForward=vec4(-v,u,k,0.0);
    // Exact great-circle motion for EVERY fixed (a,b): C''(t)=-C(t).
    // Arrow keys tilt its plane. They do not hold a nonzero latitude fixed.
    vec4 camera=origin*ct+initialForward*st;
    vec4 forward=-origin*st+initialForward*ct;
    // The transverse offset rotates with t, keeping its distance to the main
    // trail constant and both side controls nonsingular throughout the lap.
    // These normals are constant in R^4 and parallel transported along C.
    vec4 right=vec4(k,0.0,v,-u);
    vec4 down=vec4(0.0,k,-u,-v);
    vec2 uv=(screen_coords-screenCenter)/600.0;
    vec3 view=normalize(vec3(uv,0.68));
    view.xy=mat2(cos(roll),sin(roll),-sin(roll),cos(roll))*view.xy;
    view.yz=mat2(cos(pitch),sin(pitch),-sin(pitch),cos(pitch))*view.yz;
    view.xz=mat2(cos(yaw),-sin(yaw),sin(yaw),cos(yaw))*view.xz;
    vec4 direction=view.x*right+view.y*down+view.z*forward;
    float phase=time*0.23;
    vec4 moon=earthFrame(vec4(cos(ORBIT_RADIUS),sin(ORBIT_RADIUS)*cos(phase),
                   sin(ORBIT_RADIUS)*sin(phase),0.0));
    float travel=0.0;
    float cloudStop=TAU;
    vec3 radiance=vec3(0.004,0.006,0.015);
    // A ray is the exact exponential map cos(s)C+sin(s)V, never a straight
    // Euclidean ray or a projected approximation. Trace one FULL great circle:
    // rays can see the far-side images past the antipode, and close after 2pi.
    for(int i=0;i<192;i++) {
        vec4 p=camera*cos(travel)+direction*sin(travel);
        float earthDistance=distanceS3(p,EARTH)-EARTH_RADIUS;
        float moonDistance=distanceS3(p,moon)-MOON_RADIUS;
        float nearest=min(earthDistance,moonDistance);
        if(nearest<HIT_EPSILON) {
            bool earth=earthDistance<moonDistance;
            // Reverse the ray's tangent at the hit, including far-side images.
            vec4 towardCamera=normalize(camera*sin(travel)-direction*cos(travel));
            radiance=surfaceColor(p,earth ? EARTH : moon,earth,phase,towardCamera);
            cloudStop=travel;
            break;
        }
        // Intrinsic distance to the union is a conservative step by the
        // spherical triangle inequality. The factor allows for float roundoff.
        travel+=nearest*0.98;
        if(travel>TAU) break;
    }
    radiance=integrateSpaceClouds(camera,direction,cloudStop,radiance);
    return vec4(radiance,1.0)*color;
}
