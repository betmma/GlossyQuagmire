// Shared by the cached atlas and the procedural fallback. Angles are periodic.
float cloudHash(vec3 p) {
    p=fract(p*0.1031);
    p+=dot(p,p.yzx+33.33);
    return fract((p.x+p.y)*p.z);
}

float cloudNoise(vec3 p) {
    vec3 cell=floor(p),f=fract(p);
    f=f*f*f*(f*(f*6.0-15.0)+10.0);
    return mix(mix(mix(cloudHash(cell),cloudHash(cell+vec3(1,0,0)),f.x),
                   mix(cloudHash(cell+vec3(0,1,0)),cloudHash(cell+vec3(1,1,0)),f.x),f.y),
               mix(mix(cloudHash(cell+vec3(0,0,1)),cloudHash(cell+vec3(1,0,1)),f.x),
                   mix(cloudHash(cell+vec3(0,1,1)),cloudHash(cell+vec3(1,1,1)),f.x),f.y),f.z);
}

float cloudField(float theta,float t) {
    vec2 ring=vec2(cos(theta),sin(theta));
    vec3 axial=vec3(1.3*cos(t),1.3*sin(t),2.0*sin(t)+0.7*cos(2.0*t));
    // Keep each fiber coherent through the wall thickness. Fine ridges give
    // bright hair-like cores with faint feathered fringes, not rounded blobs.
    // Low axial frequencies stretch them along the local tube direction.
    vec3 q=vec3(ring*18.0,0.0)+axial;
    float warp=cloudNoise(vec3(ring*4.0,0.0)+axial);
    q+=vec3(warp-0.5,(warp-0.5)*0.7,0.0)*1.4;
    float ridge=max(0.0,1.0-abs(cloudNoise(q)*2.0-1.0));
    float small=max(0.0,1.0-abs(cloudNoise(q*2.07+vec3(9.1,2.8,5.3))*2.0-1.0));
    float fibers=pow(ridge,18.0)+0.22*pow(small,24.0)+0.045*pow(ridge,3.0);
    float coverage=smoothstep(0.44,0.67,
        cloudNoise(vec3(ring*3.0,0.0)+axial*1.8+vec3(4.1,8.7,2.3)));
    return fibers*coverage;
}
