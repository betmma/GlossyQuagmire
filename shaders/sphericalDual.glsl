// Spherical dual-disk post process.
// Source atlas:
// - primary source disk: one semisphere
// - secondary source disk: the opposite semisphere
// Exceeding part beyond hemisphere is never used for color lookup.

extern vec2 source_primary_center;
extern vec2 source_secondary_center;
extern float source_hemisphere_radius;

extern vec2 main_center;
extern float main_radius;
extern vec2 mini_center;
extern float mini_radius;

extern float cutoff_z;        // shaderCutoffZ: rim latitude control for output mapping
extern vec2 viewer_lat_lon;   // viewer orientation encoded as latitude/longitude
extern float viewer_view_direction;

extern vec2 canvas_size; // cannot use love_ScreenSize as canvas size is not same as window size (the size drawn to)

float clampf(float x, float a, float b) {
    return min(max(x, a), b);
}

// Unit-sphere inverse stereographic in normalized coordinates.
// proj_norm radius 1 corresponds to hemisphere boundary (z = 0).
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

vec2 northProjectionFromUnit(vec3 u) {
    float denom = max(1.0 - u.z, 1e-6);
    return u.xy / denom;
}

vec2 southProjectionFromUnit(vec3 u) {
    float denom = max(1.0 + u.z, 1e-6);
    return u.xy / denom;
}

vec3 unitFromLatLon(float lat, float lon) {
    float c = cos(lat);
    return vec3(c * cos(lon), c * sin(lon), sin(lat));
}

// Rotate local camera-frame unit vector to world frame.
// This is a 3D rotation, not direct lat/lon addition.
vec3 rotateLocalToWorld(vec3 u_local) {
    float lat = viewer_lat_lon.x;
    float lon = viewer_lat_lon.y;

    vec3 forward = unitFromLatLon(lat, lon);
    vec3 upRef = (abs(forward.z) < 0.999) ? vec3(0.0, 0.0, 1.0) : vec3(0.0, 1.0, 0.0);
    vec3 east0 = normalize(cross(upRef, forward));
    vec3 north0 = normalize(cross(forward, east0));
    vec3 east = east0 * cos(viewer_view_direction) + north0 * sin(viewer_view_direction);
    vec3 north = cross(forward, east);

    return normalize(east * u_local.x + north * u_local.y + forward * u_local.z);
}

// cutoff_z controls rim latitude in output disk mapping.
// With normalized stereographic coords:
// rim_radius = sqrt(1-c^2)/(1-c)
float keptProjectionRadiusNorm() {
    float c = clampf(cutoff_z, 0.0, 0.999999);
    return sqrt(max(0.0, 1.0 - c * c)) / max(1.0 - c, 1e-6);
}

vec2 sourceUv(vec2 srcCenter, vec2 srcProjNorm) {
    vec2 srcPixel = srcCenter + srcProjNorm * source_hemisphere_radius;
    return srcPixel / canvas_size;
}

vec3 worldFromOutputLocal(vec2 local, float useNorthModel, float keepR) {
    vec2 projNorm = local * keepR;
    vec3 uLocal = (useNorthModel > 0.5)
        ? unitFromNorthProjection(projNorm)
        : unitFromSouthProjection(projNorm);
    return rotateLocalToWorld(uLocal);
}

vec2 sourceUvFromWorld(vec3 uWorld) {
    // Strict hemisphere ownership for source lookup.
    if (uWorld.z <= 0.0) {
        return sourceUv(source_primary_center, northProjectionFromUnit(uWorld));
    }
    return sourceUv(source_secondary_center, southProjectionFromUnit(uWorld));
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    float keepR = keptProjectionRadiusNorm();
    vec3 uWorld = vec3(0.0);
    vec2 dMain = screen_coords - main_center;
    vec2 dMini = screen_coords - mini_center;

    if (length(dMain) <= main_radius) {
        vec2 local = dMain / max(main_radius, 1e-6);
        uWorld = worldFromOutputLocal(local, 0.0, keepR);
    }else if (length(dMini) <= mini_radius) {
        vec2 local = dMini / max(mini_radius, 1e-6);
        uWorld = worldFromOutputLocal(local, 1.0, keepR);
    }else{
        return vec4(0.0);
    }
    return Texel(tex, sourceUvFromWorld(uWorld)) * color;
}
