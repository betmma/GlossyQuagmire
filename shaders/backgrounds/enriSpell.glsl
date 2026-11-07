extern Image starMap;
extern vec2 mainCenter;
extern float mainRadius;
extern vec2 miniCenter;
extern float miniRadius;
extern vec3 cameraEast;
extern vec3 cameraNorth;
extern vec3 cameraForward;
extern float rotation;
extern float time;
extern vec3 rippleOrigin;

const float PI = 3.141592653589793;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 p = (screen_coords - mainCenter) / mainRadius;
    float hemisphere = 1.0;
    if (dot(p, p) > 1.0) {
        p = (screen_coords - miniCenter) / miniRadius;
        hemisphere = -1.0;
        if (dot(p, p) > 1.0) return vec4(0.0);
    }

    // Inverse of Spherical:toScreen's two stereographic projections.
    float r2 = dot(p, p);
    vec3 localDir = vec3(2.0 * p, hemisphere * (1.0 - r2)) / (1.0 + r2);
    vec3 worldDir = localDir.x * cameraEast + localDir.y * cameraNorth + localDir.z * cameraForward;
    // Undo the world's Y-axis rotation to keep the texture attached to it.
    float c = cos(rotation), s = sin(rotation);
    vec3 sky = normalize(vec3(c * worldDir.x + s * worldDir.z,
                              worldDir.y, -s * worldDir.x + c * worldDir.z));
    // Animate in 3D, before longitude conversion: no new seam or pole singularity.
    vec3 flow = vec3(
        sin(dot(sky, vec3(2.1, 1.3, -1.7)) + time * 0.19),
        sin(dot(sky, vec3(-1.4, 2.3, 1.1)) - time * 0.16 + 2.0),
        sin(dot(sky, vec3(1.7, -1.2, 2.0)) + time * 0.13 + 4.0));
    vec3 tangentFlow = flow - sky * dot(flow, sky);

    // One broad, gentle wave travels to the antipode in four seconds.
    float age = clamp(time / 4.0, 0.0, 1.0);
    float distanceFromOrigin = acos(clamp(dot(sky, rippleOrigin), -1.0, 1.0));
    float offset = (distanceFromOrigin - age * PI) / 0.18;
    float ripple = exp(-offset * offset) * sin(age * PI);
    vec3 away = sky * dot(sky, rippleOrigin) - rippleOrigin;
    sky = normalize(sky + 0.045 * tangentFlow + 0.018 * ripple * away);
    // Full-sphere equirectangular panorama, with a repeating longitude seam.
    float longitude = dot(sky.xy, sky.xy) > 0.00000001 ? atan(sky.y, sky.x) : 0.0;
    vec2 uv = vec2(0.5 - longitude / (2.0 * PI), acos(clamp(sky.z, -1.0, 1.0)) / PI);
    // Explicit base level avoids a derivative/mipmap seam at longitude wrap.
    vec3 stars = Texel(starMap, uv, -10.0).rgb;
    float breathing = 1.0 + 0.055 * sin(time * (2.0 * PI / 8.0));
    return vec4(stars * (breathing + 0.075 * ripple), 1.0) * color;
}
