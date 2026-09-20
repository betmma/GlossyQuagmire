uniform vec2 screenCenter;
uniform float axial_position;
uniform vec3 sphere_position;
uniform vec3 sphere_right;
uniform vec3 sphere_down;
uniform float pitch;
uniform float yaw;
uniform float roll;
uniform float sphere_radius;
uniform Image noise_lattice;
uniform bool use_noise_lattice;

const float WORLD_PERIOD = 12.0;
const float MAX_TRAVEL = 22.0;
const float FOCAL_LENGTH = 0.65;
const float TAU = 6.28318530718;

float hash31(vec3 p) {
    p = fract(p*0.1031);
    p += dot(p, p.yzx + 33.33);
    return fract((p.x + p.y)*p.z);
}

float proceduralNoise3(vec3 p) {
    vec3 cell = floor(p);
    vec3 f = fract(p);
    f = f*f*(3.0 - 2.0*f);
    return mix(
        mix(mix(hash31(cell), hash31(cell+vec3(1,0,0)), f.x),
            mix(hash31(cell+vec3(0,1,0)), hash31(cell+vec3(1,1,0)), f.x), f.y),
        mix(mix(hash31(cell+vec3(0,0,1)), hash31(cell+vec3(1,0,1)), f.x),
            mix(hash31(cell+vec3(0,1,1)), hash31(cell+vec3(1,1,1)), f.x), f.y), f.z);
}

float valueNoise3(vec3 p) {
    if(!use_noise_lattice) return proceduralNoise3(p);
    vec3 cell = floor(p)+32.0;
    // Keep edited noise scales safe if they grow beyond the cached domain.
    if(any(lessThan(cell, vec3(0.0))) || any(greaterThan(cell, vec3(126.0)))) {
        return proceduralNoise3(p);
    }
    vec3 f = fract(p);
    f = f*f*(3.0-2.0*f);
    vec2 tile0 = vec2(mod(cell.z, 16.0), floor(cell.z/16.0))*128.0;
    vec2 tile1 = vec2(mod(cell.z+1.0, 16.0), floor((cell.z+1.0)/16.0))*128.0;
    vec2 local = cell.xy+vec2(0.5)+f.xy;
    // Hardware bilinear filtering performs the same x/y interpolation;
    // interpolate between two slices explicitly for the z component.
    float a = Texel(noise_lattice, (tile0+local)/vec2(2048.0,1024.0)).r;
    float b = Texel(noise_lattice, (tile1+local)/vec2(2048.0,1024.0)).r;
    return mix(a,b,f.z);
}

float cloudNoise(vec3 p) {
    // Two octaves retain broad billows; omit the finest cloud wisps.
    float value = valueNoise3(p)*0.67;
    p = p*2.03 + vec3(11.7, 3.1, 8.4);
    return value + valueNoise3(p)*0.33;
}

float axialOffset(float z, float center) {
    return mod(z-center+WORLD_PERIOD*0.5, WORLD_PERIOD)-WORLD_PERIOD*0.5;
}

float cloudDensity(vec3 q, float z) {
    float heightA = axialOffset(z, 6.0)/1.35;
    float heightB = axialOffset(z, 10.0);
    float envelope = max(1.0-heightA*heightA, 1.0-heightB*heightB);
    if(envelope <= 0.0) return 0.0;

    float opening = smoothstep(0.06, 0.38, 1.0-q.z);
    if(opening <= 0.0) return 0.0;

    // Sample S2 directly without a longitude seam. Axial warping is periodic.
    float phase = z*TAU/WORLD_PERIOD;
    vec3 drift = vec3(cos(phase), sin(phase), sin(phase*2.0));
    float broad = valueNoise3(q*2.6 + drift*0.65 + vec3(4.2, 1.7, 8.3));
    // Detail noise is bounded by [0,1]. Skip both detail octaves when
    // even the largest possible detail cannot produce positive density.
    if(broad*0.65 + 0.35 + envelope*0.30 <= 0.62) return 0.0;
    float detail = cloudNoise(q*8.0 + drift*2.4);
    float billows = broad*0.65 + detail*0.35;
    // An opening around the ascent path. Antipodal clouds appear as curved
    // banks/rings along the different great-circle routes around S2.
    float mass = billows + envelope*0.30 - 0.62;
    return smoothstep(0.0, 0.22, mass)*opening*envelope;
}

vec3 orientRay(vec3 d) {
    d.xz = vec2(cos(yaw)*d.x + sin(yaw)*d.z, -sin(yaw)*d.x + cos(yaw)*d.z);
    d.yz = vec2(cos(pitch)*d.y - sin(pitch)*d.z, sin(pitch)*d.y + cos(pitch)*d.z);
    d.xy = vec2(cos(roll)*d.x - sin(roll)*d.y, sin(roll)*d.x + cos(roll)*d.y);
    return d;
}

vec3 skyColor(vec3 d) {
    float zenith = pow(clamp(d.z, 0.0, 1.0), 2.0);
    vec3 sky = mix(vec3(0.57, 0.75, 0.88), vec3(0.12, 0.38, 0.70), zenith);
    vec3 sunDirection = normalize(vec3(-0.35, -0.24, 1.0));
    float towardSun = max(dot(d, sunDirection), 0.0);
    sky += vec3(0.20, 0.16, 0.09)*pow(towardSun, 18.0);
    sky += vec3(0.60, 0.47, 0.27)*pow(towardSun, 450.0);
    return sky;
}

vec4 effect(vec4 color, Image texture, vec2 textureCoords, vec2 screenCoords) {
    vec2 uv = (screenCoords-screenCenter)/love_ScreenSize.y;
    vec3 d = orientRay(normalize(vec3(uv, FOCAL_LENGTH)));

    // Lua maintains this orthonormal frame by actual rotations on S2.
    // No reconstruction from planar offsets or pole-dependent denominator.
    vec3 q0 = sphere_position;
    float sphericalSpeed = length(d.xy);
    vec3 tangent = sphere_right;
    if(sphericalSpeed > 0.000001) tangent = (sphere_right*d.x+sphere_down*d.y)/sphericalSpeed;

    vec3 sky = skyColor(d);
    vec3 accumulated = vec3(0.0);
    float transmission = 1.0;
    float travel = 0.0;
    // Fixed spatial jitter breaks concentric sampling bands without flickering.
    float sampleOffset = 0.15+0.70*hash31(vec3(screenCoords, 0.37));
    for(int stepIndex=0; stepIndex<64; stepIndex++) {
        // Keep the sample lattice continuous as the camera moves. The former
        // layerDistance jump changed the number and phase of samples whenever
        // a ray crossed its 0.02 guard, producing visible popping.
        float stepLength = 0.105+travel*0.004;
        float sampleTravel = travel+stepLength*sampleOffset;
        // Exact product geodesic. Integrate density with finite steps;
        // cloud noise is not a distance bound suitable for sphere tracing.
        float angle = sampleTravel*sphericalSpeed/sphere_radius;
        vec3 q = q0*cos(angle)+tangent*sin(angle);
        float sampleZ = axial_position+d.z*sampleTravel;
        float density = cloudDensity(q, sampleZ);
        if(density > 0.0) {
            // One probe between the old near/far shadow samples.
            float above = cloudDensity(q, sampleZ+0.38);
            float sunlight = exp(-2.0*above);
            vec3 cloudColor = mix(vec3(0.36, 0.48, 0.65), vec3(1.0, 0.97, 0.88), sunlight);
            cloudColor += vec3(0.10, 0.13, 0.17)*(1.0-density);
            cloudColor = mix(cloudColor, sky, 1.0-exp(-sampleTravel*0.025));
            float opacity = 1.0-exp(-density*stepLength*3.8);
            accumulated += transmission*opacity*cloudColor;
            transmission *= 1.0-opacity;
        }
        travel += stepLength;
        if(travel > MAX_TRAVEL) break;
    }
    return vec4(clamp(accumulated+transmission*sky, 0.0, 1.0), 1.0)*color;
}
