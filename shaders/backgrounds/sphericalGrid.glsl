extern vec2 source_primary_center;
extern vec2 source_secondary_center;
extern float source_hemisphere_radius;

extern vec3 viewer_pos;
extern float viewer_dir;
extern vec3 pole_dir;
extern vec3 prime_dir;
extern vec3 split_dir;

const float PI = 3.141592653589793;
const float TAU = 6.283185307179586;

vec3 unitFromNorthProjection(vec2 proj_norm) {
    float r2 = dot(proj_norm, proj_norm);
    float inv = 1.0 / (r2 + 1.0);
    return vec3(2.0 * proj_norm.x * inv, 2.0 * proj_norm.y * inv, (r2 - 1.0) * inv);
}

vec3 unitFromSouthProjection(vec2 proj_norm) {
    float r2 = dot(proj_norm, proj_norm);
    float inv = 1.0 / (r2 + 1.0);
    return vec3(2.0 * proj_norm.x * inv, 2.0 * proj_norm.y * inv, (1.0 - r2) * inv);
}

vec3 playerLocalFromWorld(vec3 u) {
    vec3 forward = normalize(viewer_pos);
    vec3 upRef = abs(forward.z) > 0.999 ? vec3(0.0, 1.0, 0.0) : vec3(0.0, 0.0, 1.0);
    vec3 east0 = normalize(cross(upRef, forward));
    vec3 north0 = normalize(cross(forward, east0));
    vec3 east = east0 * cos(viewer_dir) + north0 * sin(viewer_dir);
    vec3 north = cross(forward, east);
    return normalize(vec3(dot(u, east), dot(u, north), dot(u, forward)));
}

float gridLine(float coord, float count, float width) {
    float d = abs(fract(coord * count + 0.5) - 0.5);
    return 1.0 - smoothstep(width, width * 2.0, d);
}

float longitudeLine(vec3 p, vec3 pole, vec3 prime, vec3 split, float count, float width) {
    vec3 aroundPole = p - pole * dot(p, pole);
    float aroundLen = length(aroundPole);
    if (aroundLen < 0.000001) {
        return 1.0;
    }
    aroundPole /= aroundLen;

    float lonAngle = atan(dot(aroundPole, split), dot(aroundPole, prime));
    float nearest = floor(lonAngle / TAU * count + 0.5) * TAU / count;
    vec3 meridianDir = normalize(prime * cos(nearest) + split * sin(nearest));
    vec3 meridianNormal = normalize(cross(pole, meridianDir));
    float angularDistance = asin(clamp(abs(dot(p, meridianNormal)), 0.0, 1.0));
    float angularWidth = width * TAU / count;
    return 1.0 - smoothstep(angularWidth, angularWidth * 2.0, angularDistance);
}

vec4 shadeSphere(vec3 u) {
    vec3 p = playerLocalFromWorld(normalize(u));
    vec3 pole = playerLocalFromWorld(normalize(pole_dir));
    vec3 prime = playerLocalFromWorld(normalize(prime_dir));
    vec3 split = playerLocalFromWorld(normalize(split_dir));
    float poleDot = clamp(dot(p, pole), -1.0, 1.0);
    float hemisphereSide = poleDot;

    vec3 colorA = vec3(0.13, 0.25, 0.43);
    vec3 colorB = vec3(0.47, 0.22, 0.16);
    vec3 base = mix(colorB, colorA, step(0.0, hemisphereSide));

    float lat = acos(poleDot) / PI;

    float latLines = gridLine(lat, 12.0, 0.018);
    float lonLines = longitudeLine(p, pole, prime, split, 24.0, 0.018);
    float splitLine = 1.0 - smoothstep(0.006, 0.018, abs(hemisphereSide));
    float line = max(max(latLines, lonLines), splitLine);

    float light = 0.82 + 0.18 * max(dot(p, normalize(vec3(-0.35, 0.45, 0.82))), 0.0);
    vec3 lineColor = vec3(0.94, 0.88, 0.68);
    return vec4(mix(base * light, lineColor, line), 1.0);
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 primary = (screen_coords - source_primary_center) / max(source_hemisphere_radius, 0.000001);
    if (dot(primary, primary) <= 1.0) {
        return shadeSphere(unitFromNorthProjection(primary)) * color;
    }

    vec2 secondary = (screen_coords - source_secondary_center) / max(source_hemisphere_radius, 0.000001);
    if (dot(secondary, secondary) <= 1.0) {
        return shadeSphere(unitFromSouthProjection(secondary)) * color;
    }

    return vec4(0.0, 0.0, 0.0, 1.0) * color;
}
