#include "shaders/H2math.glsl"
#include "shaders/H3math.glsl"
#include "shaders/honeycombMath.glsl"

uniform bool inverse; // when false, a ball of CELL_SHELL_DIST radius is cut out from solid honeycomb; when true, only the ball is solid
uniform float time;

uniform mat4 cam_mat4; // combined rotation and boost matrix
uniform vec2 screenCenter;

uniform float SHELL_RATIO; // 0.38 for small gap at edge
uniform int reflect_count; // times of camera reflection. flip coords in shade to keep continuity
uniform bool neon_lights_on;
const float MAX_HYP_DIST = 9.5;
const float STEP_MIN = 0.08;
const float STEP_MAX = 9.9;
const float STEP_FACTOR = 0.99;


vec3 honeycomb_shade(vec4 pos, vec4 dir, float travel, float time);

float atanh1(float x) {
    return 0.5 * log((1.0 + x) / max(1.0 - x, 0.000001));
}

vec3 rayMarch(vec4 cam_pos_H, vec4 ray_dir_H, float time, out bool hit_terrain) {
    float CELL_SHELL_DIST = SHELL_RATIO * CELL_INRADIUS + (1.0-SHELL_RATIO) * CELL_CIRCUMRADIUS;
    hit_terrain = false;
    vec4 pos = cam_pos_H;
    vec4 dir = normalize_spacelike(project_to_tangent(pos, ray_dir_H));
    wrap_inside_cell(pos, dir);

    vec3 accum = vec3(0.08, 0.09, 0.14);
    float travel = 0.0;
    for (int step = 0; step < 36; ++step) {
        float shellDist = acosh1(max(pos.w, 1.0));
        if (!inverse && shellDist >= CELL_SHELL_DIST || inverse && shellDist <= CELL_SHELL_DIST) {
            break;
        }

        float nearest = 1e9;
        for (int i = 0; i < FACE_COUNT; ++i) {
            vec4 faceNormal = getFaceNormal(i);
            nearest = min(nearest, plane_signed(pos, faceNormal));
        }
        nearest = max(nearest, 0.0);
        float nearestDist = asinh1(nearest);
        float dt = clamp(max(nearestDist * STEP_FACTOR, STEP_MIN), STEP_MIN, STEP_MAX);
        dt = min(dt, MAX_HYP_DIST - travel);
        dt = min(dt, abs(CELL_SHELL_DIST - shellDist));


        vec4 trialPos;
        vec4 trialDir;
        geodesic_step(pos, dir, dt, trialPos, trialDir);
        int hitFace = -1;
        float hitT = dt;
        for (int i = 0; i < FACE_COUNT; ++i) {
            vec4 faceNormal = getFaceNormal(i);
            float s1 = plane_signed(trialPos, faceNormal);
            if (s1 < 0.0) {
                float s0 = plane_signed(pos, faceNormal);
                float sd = plane_signed(dir, faceNormal);
                float ratio = -s0 / min(sd, -0.000001);
                if (ratio >= 0.0 && ratio < 0.999999) {
                    float crossingT = atanh1(ratio);
                    if (crossingT < hitT) {
                        hitT = crossingT;
                        hitFace = i;
                    }
                }
            }
        }
        if (hitFace != -1) {
            vec4 hitPos;
            vec4 hitDir;
            vec4 faceNormal = getFaceNormal(hitFace);
            geodesic_step(pos, dir, hitT, hitPos, hitDir);
            pos = reflect_plane(hitPos, faceNormal);
            dir = reflect_plane(hitDir, faceNormal);
            renormalize_state(pos, dir);
        } else {
            pos = trialPos;
            dir = trialDir;
            renormalize_state(pos, dir);
        }
        travel += dt;
        if (travel >= MAX_HYP_DIST) break;
        // if (dt <= 0.00001) {
        //     break;
        // }
    }
    vec3 sampleColor = honeycomb_shade(pos, dir, travel, time);
    accum = sampleColor;
    return accum;
}
// ---------------- Disco helpers ----------------

float hash11(vec2 p) {
    p = fract(p*vec2(123.34, 456.21));
    p += dot(p, p+34.56);
    return fract(p.x*p.y);
}

// HSV to RGB for animated beams
vec3 hsv2rgb(vec3 c) {
    vec3 p = abs(fract(c.xxx + vec3(0,2,1)/3.0)*6.0 - 3.0);
    return c.z * mix(vec3(1.0), clamp(p-1.0, 0.0, 1.0), c.y);
}

float neonSegmentMask(vec2 p, vec2 a, vec2 b, float width, float soft) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / max(dot(ba, ba), 0.000001), 0.0, 1.0);
    float d = length(pa - ba * h);
    return 1.0 - smoothstep(width, width + soft, d);
}

vec3 getRoutePointDir(int index) {
    if (index == 0) return vec3(-1.000000000000, 0.000000000000, 0.000000000000);
    if (index == 1) return vec3(-0.934172358963, 0.000000000000, -0.356822089773);
    if (index == 2) return vec3(-0.809016994375, -0.309016994375, -0.500000000000);
    if (index == 3) return vec3(-0.577350269190, -0.577350269190, -0.577350269190);
    if (index == 4) return vec3(-0.309016994375, -0.500000000000, -0.809016994375);
    if (index == 5) return vec3(0.000000000000, -0.356822089773, -0.934172358963);
    if (index == 6) return vec3(0.309016994375, -0.500000000000, -0.809016994375);
    if (index == 7) return vec3(0.577350269190, -0.577350269190, -0.577350269190);
    if (index == 8) return vec3(0.809016994375, -0.309016994375, -0.500000000000);
    if (index == 9) return vec3(0.934172358963, 0.000000000000, -0.356822089773);
    return vec3(1.000000000000, 0.000000000000, 0.000000000000);
}

int getRouteFace(int index) {
    if (index == 0) return 2;
    if (index == 1) return 1;
    if (index == 2) return 0;
    if (index == 3) return 8;
    return 9;
}

float routeBand(float dist, float width, float soft) {
    return 1.0 - smoothstep(width, width + soft, dist);
}

float neonGlowBand(float dist, float width, float glowWidth) {
    return 1.0 - smoothstep(width, glowWidth, dist);
}

float positiveRouteAngle(float a) {
    if (a < 0.0) {
        a += 2.0 * PI;
    }
    return a;
}

float hollowArrowMask(vec2 p, float stroke, float soft) {
    float top = neonSegmentMask(p, vec2(-0.130, 0.040), vec2(0.000, 0.040), stroke, soft);
    float bottom = neonSegmentMask(p, vec2(-0.130, -0.040), vec2(0.000, -0.040), stroke, soft);
    float tail = neonSegmentMask(p, vec2(-0.130, -0.040), vec2(-0.130, 0.040), stroke, soft);
    float headA = neonSegmentMask(p, vec2(0.000, 0.085), vec2(0.135, 0.000), stroke, soft);
    float headB = neonSegmentMask(p, vec2(0.000, -0.085), vec2(0.135, 0.000), stroke, soft);
    float neckA = neonSegmentMask(p, vec2(0.000, 0.085), vec2(0.000, 0.040), stroke, soft);
    float neckB = neonSegmentMask(p, vec2(0.000, -0.085), vec2(0.000, -0.040), stroke, soft);
    return clamp(max(max(max(top, bottom), max(tail, headA)), max(max(headB, neckA), neckB)), 0.0, 1.0);
}

void routeMasks(vec3 n, vec3 a, vec3 m, vec3 b, int routeFace, float shellScale,
                out float routeDist, out float arrow, out float arrowGlow,
                out float connector, out float connectorGlow) {
    vec3 planeN = normalize(getFaceNormal(routeFace).xyz);
    float planeK = 0.5 * (dot(planeN, a) + dot(planeN, b));
    vec3 circleCenter = planeN * planeK;
    float circleRadius = sqrt(max(1.0 - planeK * planeK, 0.000001));
    vec3 axisU = normalize(a - circleCenter);
    vec3 axisV = normalize(cross(planeN, axisU));
    vec3 flatM = m - circleCenter;
    flatM -= planeN * dot(flatM, planeN);
    float angleM = positiveRouteAngle(atan(dot(flatM, axisV), dot(flatM, axisU)));
    float angleB = positiveRouteAngle(atan(dot(b - circleCenter, axisV), dot(b - circleCenter, axisU)));
    vec3 flat_ = n - circleCenter;
    flat_ -= planeN * dot(flat_, planeN);
    vec3 q = circleCenter + circleRadius * normalize(flat_);
    float angleQ = positiveRouteAngle(atan(dot(q - circleCenter, axisV), dot(q - circleCenter, axisU)));
    float onArc = 0.0;
    if (angleM <= angleB) {
        onArc = step(0.0, angleQ) * step(angleQ, angleB);
    } else {
        onArc = 1.0 - step(0.0, angleQ) * step(angleQ, angleB);
    }
    float arcDist = length(n - q);
    float endDist = min(length(n - a), length(n - b));
    routeDist = mix(endDist, arcDist, onArc) * shellScale;

    vec3 arcPoint = normalize(circleCenter + circleRadius * normalize(flatM));
    vec3 forward = normalize(cross(planeN, arcPoint - circleCenter));
    if (dot(forward, b - a) < 0.0) {
        forward = -forward;
    }
    vec3 side = normalize(cross(m, forward));
    forward = normalize(cross(side, m));
    vec3 offset = n - m;
    vec2 p = vec2(dot(offset, forward), dot(offset, side)) * shellScale;
    float arrowFootprint = 1.0 - smoothstep(0.160, 0.240, length(offset) * shellScale);
    float arrowGlowFootprint = 1.0 - smoothstep(0.200, 0.380, length(offset) * shellScale);
    arrow = hollowArrowMask(p, 0.005, 0.005) * arrowFootprint;
    arrowGlow = hollowArrowMask(p, 0.050, 0.110) * arrowGlowFootprint;

    float arcSide = dot(arcPoint - m, side);
    float sideSign = arcSide < 0.0 ? -1.0 : 1.0;
    float connectorFootprint = 1.0 - smoothstep(0.160, 0.280, length(offset) * shellScale);
    connector = neonSegmentMask(p, vec2(0.000, sideSign * 0.092), vec2(0.000, sideSign * 0.155), 0.008, 0.012) * connectorFootprint;
    connectorGlow = neonSegmentMask(p, vec2(0.000, sideSign * 0.092), vec2(0.000, sideSign * 0.155), 0.040, 0.090) * connectorFootprint;
}


vec3 honeycomb_shade(vec4 pos, vec4 dir, float travel, float time) {
    float CELL_SHELL_DIST = SHELL_RATIO * CELL_INRADIUS + (1.0-SHELL_RATIO) * CELL_CIRCUMRADIUS;
    if (mod(float(reflect_count), 2.0) == 1.0){ 
        pos.xy = -pos.xy;
        dir.xy = -dir.xy;
    }
    float decay = inverse ? 0.18 : 0.38;
    // Hyperbolic distance to origin on the hyperboloid
    float d = acosh1(max(pos.w, 1.0));

    // Keep your shell logic but don’t blackout the interior
    bool outsideShell = (!inverse && d < CELL_SHELL_DIST - 0.001) ||
                        ( inverse && d > CELL_SHELL_DIST + 0.001);
    if (outsideShell) {
        return vec3(0.045, 0.055, 0.075) * exp(-decay*travel);
    }

    // Euclidean normal of the shell from your hyperbolic embedding
    float sh = max(sinh(d), 0.00001);
    float ch = cosh(d);
    vec3 N_euclid = normalize(pos.xyz / sh * ch);

    // Optional signed lighting like your original
    float Lsigned = dot(dir, vec4(N_euclid, sh));
    if (inverse) Lsigned = -Lsigned;

    float shellScale = max(sinh(d), 0.00001);
    float arrows = 0.0;
    float arrowGlow = 0.0;
    float circuits = 0.0;
    float circuitGlow = 0.0;
    float connectors = 0.0;
    float connectorGlow = 0.0;
    for (int i = 0; i < 5; ++i) {
        int routeIndex = i * 2;
        vec3 routeA = getRoutePointDir(routeIndex);
        vec3 routeM = getRoutePointDir(routeIndex + 1);
        vec3 routeB = getRoutePointDir(routeIndex + 2);
        int routeFace = getRouteFace(i);
        float routeDist;
        float routeArrow;
        float routeArrowGlow;
        float routeConnector;
        float routeConnectorGlow;
        routeMasks(N_euclid, routeA, routeM, routeB, routeFace, shellScale,
                   routeDist, routeArrow, routeArrowGlow, routeConnector, routeConnectorGlow);
        circuits = max(circuits, routeBand(routeDist, 0.006, 0.014));
        circuitGlow = max(circuitGlow, neonGlowBand(routeDist, 0.006, 0.110));
        connectors = max(connectors, routeConnector);
        connectorGlow = max(connectorGlow, routeConnectorGlow);
        arrows = max(arrows, routeArrow);
        arrowGlow = max(arrowGlow, routeArrowGlow);
    }
    vec3 V_neon = normalize(-dir.xyz);
    float rim = pow(1.0 - max(dot(N_euclid, V_neon), 0.0), 2.0);
    float facing = clamp(Lsigned, 0.0, 10.0);
    float lightLevel = neon_lights_on ? 1.0 : 0.24;
    float pulse = neon_lights_on ? (0.86 + 0.14 * sin((time - 0.05) * 5.0 * 3.141)) : 0.35;
    vec3 arrowColor = vec3(1.0, 0.18, 0.72);
    vec3 circuitColor = hsv2rgb(vec3(fract(0.60 + 0.06 * sin(time * 0.31)), 0.74, 1.0));
    vec3 base = vec3(0.025, 0.035, 0.050) + vec3(0.045, 0.055, 0.070) * facing;
    vec3 coreGlow = arrowColor * arrows * 2.70 + circuitColor * (circuits * 1.05 + connectors * 1.10);
    vec3 haloGlow = arrowColor * arrowGlow * 0.70 + circuitColor * (circuitGlow * 0.32 + connectorGlow * 0.38);
    vec3 glow = coreGlow + haloGlow;
    vec3 neonColor = base + glow * lightLevel * pulse;
    neonColor += vec3(0.08, 0.12, 0.16) * rim;
    neonColor += glow * glow * lightLevel * 0.28;
    neonColor *= exp(-decay * travel);
    return neonColor;
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = (screen_coords.xy - screenCenter) / love_ScreenSize.xy;
    uv.x *= love_ScreenSize.x / love_ScreenSize.y;

    float field_of_view_factor = 0.65;
    vec4 cam_pos_H0 = vec4(0.0, 0.0, 0.0, 1.0);
    vec3 ray_dir_on_screen = normalize(vec3(uv.x, uv.y, field_of_view_factor));
    vec4 rd_T0 = vec4(ray_dir_on_screen, 0.0);

    vec4 final_cam_pos_H = cam_mat4 * cam_pos_H0;
    vec4 final_ray_dir_H = cam_mat4 * rd_T0;

    bool terrain_was_hit;
    vec3 fragment_color = rayMarch(final_cam_pos_H, final_ray_dir_H, time, terrain_was_hit);
    fragment_color = clamp(fragment_color, 0.0, 1.0);
    return vec4(fragment_color, 1.0) * color;
}
