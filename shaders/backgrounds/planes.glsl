#include "shaders/H2math.glsl"
#include "shaders/H3math.glsl"

uniform mat4 cam_mat4;
uniform vec2 screenCenter;
uniform int reflect_count;

// const float HALF_GAP = 0.02;
const float GAP_CH = 1.00020000666676;       // cosh(HALF_GAP)
const float GAP_SH = 0.0200013333600003;     // sinh(HALF_GAP)
const float MAX_COLUMN_HEIGHT = 0.81;
const float MAX_HYP_DIST = 9.0;
const float FIELD_OF_VIEW_FACTOR = 0.65;
const float STEP_FACTOR = 0.4;
const float HIT_EPS = 0.01;
const float MIRROR_EXIT_STEP = 0.000;
const float INV_LOG2 = 1.4426950408889634;
const float TAU = 6.28318530718;
const float SIDE_FACE_NONE = 9.0;
const float COLUMN_UV_MIN = 0.30;
const float COLUMN_UV_MAX = 0.70;
// const float MIRROR_OFFSET = 4.61;
const float MIRROR_CH = 50.24705072734862;    // cosh(MIRROR_OFFSET)
const float MIRROR_SH = 50.23709890904077;    // sinh(MIRROR_OFFSET)
const vec2 RELIEF_LIGHT_DIR = vec2(-0.552380364401192, 0.833592186278162);

float asinh1(float x) {
    float ax = abs(x);
    return sign(x) * log(ax + sqrt(ax * ax + 1.0));
}

float asinhPositive(float x) {
    return log(x + sqrt(x * x + 1.0));
}

void sinhCoshFast(float x, out float sh, out float ch) {
    float ex = exp(x);
    float invEx = 1.0 / ex;
    sh = 0.5 * (ex - invEx);
    ch = 0.5 * (ex + invEx);
}

float sinhFast(float x) {
    float ex = exp(x);
    return 0.5 * (ex - 1.0 / ex);
}

float atanh1(float x) {
    return 0.5 * log((1.0 + x) / max(1.0 - x, 0.000001));
}

vec4 normalize_spacelike_local(vec4 v) {
    float n2 = -minkowski_dot(v, v);
    return v / sqrt(max(n2, 0.000001));
}

vec4 project_to_tangent_local(vec4 p, vec4 v) {
    return v - minkowski_dot(p, v) * p;
}

void geodesic_step_local(vec4 pos, vec4 dir, float t, out vec4 pos_out, out vec4 dir_out) {
    float sh;
    float ch;
    sinhCoshFast(t, sh, ch);
    pos_out = ch * pos + sh * dir;
    dir_out = sh * pos + ch * dir;
}

void renormalize_state_local(inout vec4 pos, inout vec4 dir) {
    float posNorm = sqrt(max(minkowski_dot(pos, pos), 0.000001));
    pos /= posNorm;
    dir = project_to_tangent_local(pos, dir);
    dir = normalize_spacelike_local(dir);
}

vec4 gapPlaneNormal(float side) {
    return vec4(0.0, side * GAP_CH, 0.0, GAP_SH);
}

vec4 footOnHyperbolicPlane(vec4 pos, vec4 normal, out float signedDistance) {
    float signedSinhDistance = minkowski_dot(pos, normal);
    signedDistance = asinh1(signedSinhDistance);
    float invCoshDistance = 1.0 / sqrt(max(1.0 + signedSinhDistance * signedSinhDistance, 0.000001));
    return (pos + signedSinhDistance * normal) * invCoshDistance;
}

vec4 footOnGapPlane(vec4 pos, float side, out float signedDistance, out float coshDistance) {
    float signedSinhDistance = pos.w * GAP_SH - side * pos.y * GAP_CH;
    signedDistance = asinh1(signedSinhDistance);
    coshDistance = sqrt(max(1.0 + signedSinhDistance * signedSinhDistance, 0.000001));
    float invCoshDistance = 1.0 / coshDistance;
    return vec4(pos.x,
                pos.y + signedSinhDistance * side * GAP_CH,
                pos.z,
                pos.w + signedSinhDistance * GAP_SH) * invCoshDistance;
}

vec4 mirrorPlaneNormal(float side) {
    return vec4(side * MIRROR_CH, 0.0, 0.0, MIRROR_SH);
}

vec4 unboostGapPlane(vec4 pos, float side) {
    float y = GAP_CH * pos.y - side * GAP_SH * pos.w;
    float w = -side * GAP_SH * pos.y + GAP_CH * pos.w;
    return vec4(pos.x, y, pos.z, w);
}

float hash21(vec2 p) {
    p = fract(p * vec2(127.13, 311.71));
    p += dot(p, p + 37.29);
    return fract(p.x * p.y);
}

float tileHash(float row, float col, float planeId) {
    return hash21(vec2(col + planeId * 19.17, row + planeId * 43.31));
}

vec2 planeUpperHalfCoords(vec4 planePoint, float side) {
    vec4 q = unboostGapPlane(planePoint, side);
    float invDepth = 1.0 / max(q.w - q.x, 0.00001);
    return vec2(q.z * invDepth, invDepth);
}

void binaryTile(vec2 uv, out float row, out float col, out vec2 localUv) {
    float y = max(uv.y, 0.0001);
    row = floor(log(y) * INV_LOG2);
    float invScale = exp2(-row);
    vec2 tileUv = vec2(uv.x, y) * invScale;
    col = floor(tileUv.x);
    localUv = fract(tileUv);
}

float columnHeight(float row, float col, float planeId) {
    float h0 = tileHash(row, col, planeId);
    float h1 = tileHash(row + 11.0, col - 7.0, planeId);
    float shaped = h0 * h0 * 0.70 + h1 * 0.30;
    return MAX_COLUMN_HEIGHT * shaped;
}

float verticalEdgeDistance(float localX, float localY) {
    return asinhPositive(localX / (1.0 + localY));
}

float horizontalEdgeDistance(float localY, float edgeY) {
    return abs(log(max((1.0 + localY) / max(1.0 + edgeY, 0.0001), 0.0001)));
}

float signedInsetRectDistance(vec2 localUv, out float sideFace, float depth) {
    float delta = smoothstep(0.0,0.5,depth)*depth*0.3;
    float uvMin = max(COLUMN_UV_MIN - delta, 0.0);
    float uvMax = min(COLUMN_UV_MAX + delta, 1.0);

    bool insideX = localUv.x >= uvMin && localUv.x <= uvMax;
    bool insideY = localUv.y >= uvMin && localUv.y <= uvMax;

    if (insideX && insideY) {
        float left = verticalEdgeDistance(localUv.x - uvMin, localUv.y);
        float right = verticalEdgeDistance(uvMax - localUv.x, localUv.y);
        float bottom = horizontalEdgeDistance(localUv.y, uvMin);
        float top = horizontalEdgeDistance(localUv.y, uvMax);
        float nearest = left;
        sideFace = 0.0;
        if (right < nearest) {
            nearest = right;
            sideFace = 1.0;
        }
        if (bottom < nearest) {
            nearest = bottom;
            sideFace = 2.0;
        }
        if (top < nearest) {
            nearest = top;
            sideFace = 3.0;
        }
        return -nearest;
    }

    float dx = 0.0;
    float dy = 0.0;
    sideFace = SIDE_FACE_NONE;
    if (!insideX) {
        if (localUv.x < uvMin) {
            dx = verticalEdgeDistance(uvMin - localUv.x, localUv.y);
            sideFace = 0.0;
        } else {
            dx = verticalEdgeDistance(localUv.x - uvMax, localUv.y);
            sideFace = 1.0;
        }
    }
    if (!insideY) {
        if (localUv.y < uvMin) {
            dy = horizontalEdgeDistance(localUv.y, uvMin);
            if (dx <= dy) {
                sideFace = 2.0;
            }
        } else {
            dy = horizontalEdgeDistance(localUv.y, uvMax);
            if (dx <= dy) {
                sideFace = 3.0;
            }
        }
    }
    return sqrt(dx * dx + dy * dy);
}

float tangentDot(vec4 a, vec4 b) {
    return -minkowski_dot(a, b);
}

float planeColumnSdf(vec4 pos, float side, float planeId,
                     out vec2 localUv, out float height,
                     out float signedDistance, out float faceType, out float sideFace,
                     out float materialSeed) {
    vec4 planeFoot;
    float coshDistance;
    planeFoot = footOnGapPlane(pos, side, signedDistance, coshDistance);
    vec2 uv = planeUpperHalfCoords(planeFoot, side);
    float row;
    float col;
    binaryTile(uv, row, col, localUv);
    height = columnHeight(row, col, planeId);
    materialSeed = tileHash(row + 23.0, col + 41.0, planeId);
    float depth = -signedDistance;
    float rectSideFace;
    float rectSdf = signedInsetRectDistance(localUv, rectSideFace, depth);
    rectSdf = asinh1(sinhFast(rectSdf) * coshDistance);
    float frontSdf = height - depth;
    float columnSdf = max(rectSdf, frontSdf);

    faceType = 0.0;
    sideFace = SIDE_FACE_NONE;
    if (rectSdf > frontSdf) {
        faceType = 1.0;
        sideFace = rectSideFace;
    }
    return columnSdf;
}

float sceneSdf(vec4 pos, out float hitSide, out vec2 localUv, out float height,
               out float signedDistance, out float faceType, out float sideFace,
               out float materialSeed) {
    vec2 uv0;
    vec2 uv1;
    float height0;
    float height1;
    float dist0;
    float dist1;
    float faceType0;
    float faceType1;
    float sideFace0;
    float sideFace1;
    float materialSeed0;
    float materialSeed1;
    float sdf0 = planeColumnSdf(pos, 1.0, 0.0, uv0, height0, dist0, faceType0, sideFace0, materialSeed0);
    float sdf1 = planeColumnSdf(pos, -1.0, 1.0, uv1, height1, dist1, faceType1, sideFace1, materialSeed1);

    float columnSdf = sdf0;
    hitSide = 1.0;
    localUv = uv0;
    height = height0;
    signedDistance = dist0;
    faceType = faceType0;
    sideFace = sideFace0;
    materialSeed = materialSeed0;

    if (sdf1 < columnSdf) {
        columnSdf = sdf1;
        hitSide = -1.0;
        localUv = uv1;
        height = height1;
        signedDistance = dist1;
        faceType = faceType1;
        sideFace = sideFace1;
        materialSeed = materialSeed1;
    }

    return columnSdf;
}

float seamMask(vec2 localUv) {
    float edgeDist = min(min(localUv.x, 1.0 - localUv.x), min(localUv.y, 1.0 - localUv.y));
    return 1.0 - smoothstep(0.018, 0.055, edgeDist);
}

float valueNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float surfaceBump(vec2 uv, float h) {
    float broad = valueNoise(uv * 18.0 + h * vec2(11.3, 5.7));
    float grain = valueNoise(uv * 73.0 - h * vec2(2.1, 13.6));
    float ridge = sin((uv.x * 13.0 + uv.y * 7.0 + h * 5.0) * TAU);
    return broad * 0.080 + grain * 0.025 + ridge * 0.012;
}

vec2 surfaceBumpGradient(vec2 bumpUv, float heightRatio) {
    float eps = 0.012;
    float bumpR = surfaceBump(bumpUv + vec2(eps, 0.0), heightRatio);
    float bumpL = surfaceBump(bumpUv - vec2(eps, 0.0), heightRatio);
    float bumpT = surfaceBump(bumpUv + vec2(0.0, eps), heightRatio);
    float bumpB = surfaceBump(bumpUv - vec2(0.0, eps), heightRatio);
    vec2 grad = vec2(bumpR - bumpL, bumpT - bumpB) / (2.0 * eps);
    return clamp(grad, vec2(-2.5), vec2(2.5));
}

vec3 localSideNormal(float sideFace) {
    if (sideFace < 0.5) {
        return vec3(0.0, 0.0, -1.0);
    }
    if (sideFace < 1.5) {
        return vec3(0.0, 0.0, 1.0);
    }
    if (sideFace < 2.5) {
        return vec3(-1.0, 0.0, 0.0);
    }
    return vec3(1.0, 0.0, 0.0);
}

vec4 surfaceTangentAxis(vec4 pos, vec4 normal4, vec4 hint) {
    vec4 axis = project_to_tangent_local(pos, hint);
    axis -= tangentDot(axis, normal4) * normal4;
    return normalize_spacelike_local(axis);
}

void reflectAcrossHyperbolicPlane(inout vec4 pos, inout vec4 dir, vec4 planeNormal) {
    float signedDistance;
    vec4 foot = footOnHyperbolicPlane(pos, planeNormal, signedDistance);
    dir = normalize_spacelike_local(dir + 2.0 * minkowski_dot(dir, planeNormal) * planeNormal);
    pos = foot;
    renormalize_state_local(pos, dir);
}

bool mirrorCrossingBefore(vec4 pos, vec4 dir, float maxT, out vec4 hitMirrorNormal, out float hitT) {
    bool hitMirror = false;
    hitT = maxT;

    float hitSide = 0.0;
    float s0Right = pos.w * MIRROR_SH - pos.x * MIRROR_CH;
    float sdRight = dir.w * MIRROR_SH - dir.x * MIRROR_CH;
    if (sdRight < -0.000001) {
        float ratio = -s0Right / sdRight;
        if (ratio >= 0.0 && ratio < 0.999999) {
            float crossingT = atanh1(ratio);
            if (crossingT <= hitT) {
                hitT = crossingT;
                hitSide = 1.0;
                hitMirror = true;
            }
        }
    }

    float s0Left = pos.w * MIRROR_SH + pos.x * MIRROR_CH;
    float sdLeft = dir.w * MIRROR_SH + dir.x * MIRROR_CH;
    if (sdLeft < -0.000001) {
        float ratio = -s0Left / sdLeft;
        if (ratio >= 0.0 && ratio < 0.999999) {
            float crossingT = atanh1(ratio);
            if (crossingT <= hitT) {
                hitT = crossingT;
                hitSide = -1.0;
                hitMirror = true;
            }
        }
    }

    hitMirrorNormal = mirrorPlaneNormal(hitSide);
    return hitMirror && hitT <= maxT;
}

vec4 perturbSurfaceNormal(vec4 normal4, vec4 axisU, vec4 axisV,
                          vec2 grad, float strength) {
    return normalize_spacelike_local(normal4 - strength * (axisU * grad.x + axisV * grad.y));
}

vec3 columnPalette(float seed, float heightRatio, float faceType) {
    vec3 basalt = vec3(0.150, 0.170, 0.180);
    vec3 slate = vec3(0.190, 0.250, 0.285);
    vec3 oxidized = vec3(0.210, 0.315, 0.270);
    vec3 ochre = vec3(0.475, 0.330, 0.175);
    vec3 rose = vec3(0.560, 0.245, 0.285);

    vec3 tone = mix(basalt, slate, smoothstep(0.10, 0.45, seed));
    tone = mix(tone, oxidized, smoothstep(0.42, 0.70, seed) * 0.75);
    tone = mix(tone, ochre, smoothstep(0.68, 0.88, seed) * 0.65);
    tone = mix(tone, rose, smoothstep(0.84, 1.00, seed) * 0.55);

    vec3 sunBleach = vec3(0.980, 0.735, 0.500);
    tone = mix(tone, sunBleach, 0.18 + 0.22 * heightRatio);
    tone = mix(tone, vec3(0.070, 0.085, 0.095), faceType * 0.30);
    return tone;
}

vec3 shadeSurface(vec4 pos, vec4 dir, float travel, float side,
                  vec2 localUv, float height, float signedDistance,
                  float faceType, float sideFace, float materialSeed) {
    float heightRatio = clamp(height / MAX_COLUMN_HEIGHT, 0.0, 1.0);
    float seam = seamMask(localUv);
    float depthRatio = clamp((-signedDistance) / max(height, 0.0001), 0.0, 1.0);

    float surfaceMottle = valueNoise(localUv * 9.0 + vec2(materialSeed * 17.0, heightRatio * 5.0));
    vec3 basalt = columnPalette(materialSeed, heightRatio, faceType);
    basalt *= 0.86 + 0.25 * surfaceMottle;
    basalt *= 1.0 - seam * 0.18;

    vec4 planeN = gapPlaneNormal(side);
    vec4 normal4 = normalize_spacelike_local(project_to_tangent_local(pos, planeN));
    vec2 bumpUv = localUv;
    vec4 bumpAxisU = surfaceTangentAxis(pos, normal4, vec4(0.0, 0.0, 1.0, 0.0));
    vec4 bumpAxisV = surfaceTangentAxis(pos, normal4, vec4(1.0, 0.0, 0.0, 0.0));
    if (faceType > 0.5) {
        vec3 localN = localSideNormal(sideFace);
        normal4 = normalize_spacelike_local(project_to_tangent_local(pos, vec4(localN.x, 0.0, localN.z, 0.0)));
        if (tangentDot(normal4, -dir) < 0.0) {
            normal4 = -normal4;
        }
        bumpAxisV = surfaceTangentAxis(pos, normal4, planeN);
        if (sideFace < 1.5) {
            bumpUv = vec2(localUv.y, depthRatio);
            bumpAxisU = surfaceTangentAxis(pos, normal4, vec4(1.0, 0.0, 0.0, 0.0));
        } else {
            bumpUv = vec2(localUv.x, depthRatio);
            bumpAxisU = surfaceTangentAxis(pos, normal4, vec4(0.0, 0.0, 1.0, 0.0));
        }
        float sideStrata = sin((depthRatio * 9.0 + heightRatio * 4.0) * TAU) * 0.5 + 0.5;
        vec3 coolShadow = vec3(0.035, 0.055, 0.070);
        vec3 warmStrata = vec3(0.130, 0.082, 0.035);
        basalt = mix(coolShadow, basalt, 0.38 + 0.48 * depthRatio);
        basalt += warmStrata * sideStrata * (0.32 + 0.22 * materialSeed);
    }
    vec2 bumpGrad = surfaceBumpGradient(bumpUv, heightRatio);
    float bumpStrength = mix(0.095, 0.125, faceType) * (0.65 + 0.35 * heightRatio);
    normal4 = perturbSurfaceNormal(normal4, bumpAxisU, bumpAxisV, bumpGrad, bumpStrength);

    float cameraLight = clamp(abs(tangentDot(normal4, dir)), 0.0, 1.0);
    float topLight = mix(0.60, cameraLight, 0.36);
    float sideLight = mix(0.36, cameraLight, 0.78);
    float diffuse = mix(topLight, sideLight, faceType);
    float rim = pow(1.0 - cameraLight, 2.0) * faceType;

    vec3 color = basalt * (0.34 + 0.76 * diffuse);
    float reliefLight = 1.0 + dot(bumpGrad, RELIEF_LIGHT_DIR) * mix(0.050, 0.075, faceType);
    color *= clamp(reliefLight, 0.82, 1.20);
    if (faceType > 0.5) {
        color *= 0.70;
    }
    color += vec3(0.230, 0.285, 0.315) * rim * 0.42;
    color += vec3(0.055, 0.080, 0.070) * (1.0 - seam) * heightRatio;
    color = pow(max(color, vec3(0.0)), vec3(0.92));
    // color = vec3(fract(-signedDistance),fract(-signedDistance/3.0),fract(-signedDistance/9.0));
    float fog = 1.0 - exp(-0.155 * travel);
    vec3 fogColor = mix(vec3(0.030, 0.040, 0.055), vec3(0.075, 0.065, 0.050), heightRatio * 0.35);
    return mix(color, fogColor, fog);
}

vec3 rayMarch(vec4 cam_pos_H, vec4 ray_dir_H) {
    vec4 pos = cam_pos_H;
    vec4 dir = normalize_spacelike_local(project_to_tangent_local(pos, ray_dir_H));
    float travel = 0.0;

    float hitSide;
    vec2 localUv;
    float height;
    float signedDistance;
    float faceType;
    float sideFace;
    float materialSeed;
    float sdfValue;
    for (int step = 0; step < 96; ++step) {
        sdfValue = sceneSdf(pos, hitSide, localUv, height, signedDistance, faceType, sideFace, materialSeed);
        if (sdfValue < HIT_EPS) {
            return shadeSurface(pos, dir, travel, hitSide, localUv, height, signedDistance, faceType, sideFace, materialSeed);
        }
        float dt = sdfValue * STEP_FACTOR;

        vec4 hitMirrorNormal;
        float hitMirrorT;
        if (mirrorCrossingBefore(pos, dir, dt, hitMirrorNormal, hitMirrorT)) {
            vec4 hitPos;
            vec4 hitDir;
            geodesic_step_local(pos, dir, hitMirrorT, hitPos, hitDir);
            pos = hitPos;
            dir = hitDir;
            reflectAcrossHyperbolicPlane(pos, dir, hitMirrorNormal);
            travel += hitMirrorT + MIRROR_EXIT_STEP;
            if (travel >= MAX_HYP_DIST) {
                break;
            }
            continue;
        }

        vec4 nextPos;
        vec4 nextDir;
        geodesic_step_local(pos, dir, dt, nextPos, nextDir);
        pos = nextPos;
        dir = nextDir;
        renormalize_state_local(pos, dir);

        travel += dt;
        if (travel >= MAX_HYP_DIST) {
            break;
        }
    }

    return vec3(0.020, 0.026, 0.034);
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = (screen_coords.xy - screenCenter) / love_ScreenSize.xy;
    uv.x *= love_ScreenSize.x / love_ScreenSize.y;

    vec4 cam_pos_H0 = vec4(0.0, 0.0, 0.0, 1.0);
    vec3 ray_dir_on_screen = normalize(vec3(uv.x, uv.y, FIELD_OF_VIEW_FACTOR));
    vec4 rd_T0 = vec4(ray_dir_on_screen, 0.0);

    vec4 final_cam_pos_H = cam_mat4 * cam_pos_H0;
    vec4 final_ray_dir_H = cam_mat4 * rd_T0;
    if (mod(float(reflect_count), 2.0) == 1.0) {
        final_cam_pos_H.x = -final_cam_pos_H.x;
        final_ray_dir_H.x = -final_ray_dir_H.x;
    }

    vec3 fragment_color = rayMarch(final_cam_pos_H, final_ray_dir_H);
    fragment_color = clamp(fragment_color, 0.0, 1.0);
    return vec4(fragment_color, 1.0) * color;
}
