#include "shaders/H2math.glsl"
#include "shaders/H3math.glsl"

uniform mat4 cam_mat4;
uniform vec2 screenCenter;

const float HALF_GAP = 0.02;
const float MAX_COLUMN_HEIGHT = 0.31;
const float MAX_HYP_DIST = 9.5;
const float FIELD_OF_VIEW_FACTOR = 0.65;
const float STEP_FACTOR = 0.98;
const float HIT_EPS = 0.0012;
const float LOG2_VALUE = 0.6931471805599453;
const float SIDE_FACE_NONE = 9.0;
const float COLUMN_UV_MIN = 0.30;
const float COLUMN_UV_MAX = 0.70;

float asinh1(float x) {
    return log(x + sqrt(x * x + 1.0));
}

vec4 normalize_spacelike_local(vec4 v) {
    float n2 = -minkowski_dot(v, v);
    return v / sqrt(max(n2, 0.000001));
}

vec4 project_to_tangent_local(vec4 p, vec4 v) {
    return v - minkowski_dot(p, v) * p;
}

void geodesic_step_local(vec4 pos, vec4 dir, float t, out vec4 pos_out, out vec4 dir_out) {
    float ch = cosh(t);
    float sh = sinh(t);
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
    float ch = cosh(HALF_GAP);
    float sh = sinh(HALF_GAP);
    return vec4(0.0, side * ch, 0.0, sh);
}

vec4 footOnGapPlane(vec4 pos, float side, out float signedDistance) {
    vec4 normal = gapPlaneNormal(side);
    float signedSinhDistance = minkowski_dot(pos, normal);
    signedDistance = asinh1(signedSinhDistance);
    float invCoshDistance = 1.0 / sqrt(max(1.0 + signedSinhDistance * signedSinhDistance, 0.000001));
    return (pos - signedSinhDistance * normal) * invCoshDistance;
}

vec4 unboostGapPlane(vec4 pos, float side) {
    float ch = cosh(HALF_GAP);
    float sh = sinh(HALF_GAP);
    float y = ch * pos.y - side * sh * pos.w;
    float w = -side * sh * pos.y + ch * pos.w;
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
    float depth = max(q.w - q.x, 0.00001);
    return vec2(q.z / depth, 1.0 / depth);
}

void binaryTile(vec2 uv, out float row, out float col, out vec2 localUv) {
    float y = max(uv.y, 0.0001);
    row = floor(log(y) / LOG2_VALUE);
    float scale = pow(2.0, row);
    col = floor(uv.x / scale);
    localUv = vec2(fract(uv.x / scale), fract(y / scale));
}

float columnHeight(float row, float col, float planeId) {
    float h0 = tileHash(row, col, planeId);
    float h1 = tileHash(row + 11.0, col - 7.0, planeId);
    float shaped = h0 * h0 * 0.70 + h1 * 0.30;
    return MAX_COLUMN_HEIGHT * shaped;
}

float verticalEdgeDistance(float localX, float localY) {
    float yRatio = 1.0 + localY;
    return asinh1(localX / max(yRatio, 0.0001));
}

float horizontalEdgeDistance(float localY, float edgeY) {
    return abs(log(max((1.0 + localY) / max(1.0 + edgeY, 0.0001), 0.0001)));
}

float signedInsetRectDistance(vec2 localUv, out float sideFace) {
    float left = verticalEdgeDistance(abs(localUv.x - COLUMN_UV_MIN), localUv.y);
    float right = verticalEdgeDistance(abs(COLUMN_UV_MAX - localUv.x), localUv.y);
    float bottom = horizontalEdgeDistance(localUv.y, COLUMN_UV_MIN);
    float top = horizontalEdgeDistance(localUv.y, COLUMN_UV_MAX);

    bool insideX = localUv.x >= COLUMN_UV_MIN && localUv.x <= COLUMN_UV_MAX;
    bool insideY = localUv.y >= COLUMN_UV_MIN && localUv.y <= COLUMN_UV_MAX;

    if (insideX && insideY) {
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
    if (!insideX) {
        if (localUv.x < COLUMN_UV_MIN) {
            dx = left;
            sideFace = 0.0;
        } else {
            dx = right;
            sideFace = 1.0;
        }
    }
    if (!insideY) {
        if (localUv.y < COLUMN_UV_MIN) {
            dy = bottom;
            if (dx <= dy) {
                sideFace = 2.0;
            }
        } else {
            dy = top;
            if (dx <= dy) {
                sideFace = 3.0;
            }
        }
    }
    return sqrt(dx * dx + dy * dy);
}

float columnSideSurfaceDistance(float rectSdf, float frontSdf) {
    float sideDist = abs(rectSdf);
    if (frontSdf > 0.0) {
        sideDist = sqrt(sideDist * sideDist + frontSdf * frontSdf);
    }
    return sideDist;
}

float columnCapSurfaceDistance(float rectSdf, float frontSdf) {
    float capDist = abs(frontSdf);
    if (rectSdf > 0.0) {
        capDist = sqrt(rectSdf * rectSdf + capDist * capDist);
    }
    return capDist;
}

float tangentDot(vec4 a, vec4 b) {
    return -minkowski_dot(a, b);
}

float planeColumnSdf(vec4 pos, float side, float planeId,
                     out vec2 localUv, out float height,
                     out float signedDistance, out float faceType, out float sideFace) {
    vec4 planeFoot;
    planeFoot = footOnGapPlane(pos, side, signedDistance);
    vec2 uv = planeUpperHalfCoords(planeFoot, side);
    float row;
    float col;
    binaryTile(uv, row, col, localUv);
    height = columnHeight(row, col, planeId);
    float depth = -signedDistance;
    float rectSideFace;
    float rectSdf = signedInsetRectDistance(localUv, rectSideFace);
    float frontSdf = height - depth;
    float sideSurfaceDist = columnSideSurfaceDistance(rectSdf, frontSdf);
    float capSurfaceDist = columnCapSurfaceDistance(rectSdf, frontSdf);
    float columnSdf = min(sideSurfaceDist, capSurfaceDist);

    faceType = 0.0;
    sideFace = SIDE_FACE_NONE;
    if (sideSurfaceDist < capSurfaceDist) {
        faceType = 1.0;
        sideFace = rectSideFace;
    }
    return columnSdf;
}

float sceneSdf(vec4 pos, out float hitSide, out vec2 localUv, out float height,
               out float signedDistance, out float faceType, out float sideFace) {
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
    float sdf0 = planeColumnSdf(pos, 1.0, 0.0, uv0, height0, dist0, faceType0, sideFace0);
    float sdf1 = planeColumnSdf(pos, -1.0, 1.0, uv1, height1, dist1, faceType1, sideFace1);

    if (sdf0 <= sdf1) {
        hitSide = 1.0;
        localUv = uv0;
        height = height0;
        signedDistance = dist0;
        faceType = faceType0;
        sideFace = sideFace0;
        return sdf0;
    }

    hitSide = -1.0;
    localUv = uv1;
    height = height1;
    signedDistance = dist1;
    faceType = faceType1;
    sideFace = sideFace1;
    return sdf1;
}

float seamMask(vec2 localUv) {
    float edgeDist = min(min(localUv.x, 1.0 - localUv.x), min(localUv.y, 1.0 - localUv.y));
    return 1.0 - smoothstep(0.018, 0.055, edgeDist);
}

float columnTopDetail(vec2 localUv, float h) {
    vec2 p = localUv - vec2(0.5, 0.5);
    float ring = sin((length(p) * 3.0 + h * 31.0) * 6.28318530718) * 0.5 + 0.5;
    float ridge = sin((localUv.x * 8.0 + localUv.y * 5.0 + h * 17.0) * 6.28318530718) * 0.5 + 0.5;
    return ring * 0.08 + ridge * 0.06;
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

vec3 shadeSurface(vec4 pos, vec4 dir, float travel, float side,
                  vec2 localUv, float height, float signedDistance,
                  float faceType, float sideFace) {
    float heightRatio = clamp(height / MAX_COLUMN_HEIGHT, 0.0, 1.0);
    float seam = seamMask(localUv);
    float detail = columnTopDetail(localUv, heightRatio);
    float depthRatio = clamp((-signedDistance) / max(height, 0.0001), 0.0, 1.0);

    vec3 baseDark = vec3(0.030, 0.036, 0.041);
    vec3 baseLight = vec3(0.325, 0.334, 0.338);
    vec3 basalt = mix(baseDark, baseLight, 0.32 + 0.52 * heightRatio + detail);
    basalt *= 1.0 - seam * 0.18;

    vec4 planeN = gapPlaneNormal(side);
    vec4 normal4 = normalize_spacelike_local(project_to_tangent_local(pos, planeN));
    if (faceType > 0.5) {
        vec3 localN = localSideNormal(sideFace);
        normal4 = normalize_spacelike_local(project_to_tangent_local(pos, vec4(localN.x, 0.0, localN.z, 0.0)));
        if (tangentDot(normal4, -dir) < 0.0) {
            normal4 = -normal4;
        }
        float sideStrata = sin((depthRatio * 9.0 + heightRatio * 4.0) * 6.28318530718) * 0.5 + 0.5;
        basalt = mix(vec3(0.012, 0.015, 0.018), basalt, 0.32 + 0.46 * depthRatio);
        basalt += vec3(0.018, 0.016, 0.012) * sideStrata * 5.0;
    }

    float cameraLight = clamp(abs(tangentDot(normal4, dir)), 0.0, 1.0);
    float topLight = mix(0.72, cameraLight, 0.16);
    float sideLight = mix(0.36, cameraLight, 0.78);
    float diffuse = mix(topLight, sideLight, faceType);
    float rim = pow(1.0 - cameraLight, 2.0) * faceType;

    vec3 color = basalt * (0.34 + 0.76 * diffuse);
    if (faceType > 0.5) {
        color *= 0.70;
    }
    color += vec3(0.16, 0.19, 0.21) * rim * 0.32;
    color += vec3(0.030, 0.045, 0.060) * (1.0 - seam) * heightRatio;

    float fog = 1.0 - exp(-0.105 * travel);
    vec3 fogColor = vec3(0.020, 0.026, 0.034);
    return mix(color, fogColor, fog)*4.0;
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
    float sdfValue;
    for (int step = 0; step < 96; ++step) {
        sdfValue = sceneSdf(pos, hitSide, localUv, height, signedDistance, faceType, sideFace);
        if (sdfValue < HIT_EPS) {
            return shadeSurface(pos, dir, travel, hitSide, localUv, height, signedDistance, faceType, sideFace);
        }
        float dt = sdfValue * STEP_FACTOR;

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

    vec3 fragment_color = rayMarch(final_cam_pos_H, final_ray_dir_H);
    fragment_color = clamp(fragment_color, 0.0, 1.0);
    return vec4(fragment_color, 1.0) * color;
}
