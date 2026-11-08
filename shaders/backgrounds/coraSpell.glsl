extern vec2 resolution;
extern vec2 screenCenter;
extern float roll;
extern vec2 look;
extern vec3 cameraPosition;
extern float viewDistance;
extern float fogDensity;

vec4 effect(vec4 color, Image texture, vec2 uv, vec2 pixel) {
    vec2 screen = 2.0 * (pixel - screenCenter) / resolution.y;
    screen.y = -screen.y;
    float cr = cos(roll), sr = sin(roll);
    screen = mat2(cr, sr, -sr, cr) * screen;
    vec3 ray = normalize(vec3(screen, 1.40));
    float cp = cos(look.y), sp = sin(look.y);
    float cy = cos(look.x), sy = sin(look.x);
    ray.yz = mat2(cp, sp, -sp, cp) * ray.yz;
    ray.xz = mat2(cy, sy, -sy, cy) * ray.xz;

    vec3 origin = cameraPosition;
    vec3 cell = floor(origin);
    vec3 stepDir = mix(vec3(-1.0), vec3(1.0), step(vec3(0.0), ray));
    vec3 delta = 1.0 / max(abs(ray), vec3(0.000001));
    vec3 boundary = cell + step(vec3(0.0), ray);
    vec3 next = abs(boundary - origin) * delta;
    float entry = 0.0;

    // Traverse grid cells in order, intersecting one real sphere per cell.
    // No curved space, recursive copies, or fractal distance estimator.
    for (int i = 0; i < 40; i++) {
        if (entry > viewDistance) break;
        float leave = min(next.x, min(next.y, next.z));
        vec3 center = cell + vec3(0.5);
        vec3 offset = origin - center;
        float b = dot(offset, ray);
        float discriminant = b * b - dot(offset, offset) + 0.13 * 0.13;
        if (discriminant > 0.0) {
            float t = -b - sqrt(discriminant);
            // Free flight can enter a balloon: show its inner surface too.
            if (t < 0.0) t = -b + sqrt(discriminant);
            if (t >= entry - 0.0001 && t <= leave + 0.0001 && t <= viewDistance) {
                vec3 normal = normalize(origin + t * ray - center);
                if (dot(normal, ray) > 0.0) normal = -normal;
                vec3 light = normalize(vec3(-0.45, 0.75, -0.65));
                // Wrapped light and strong ambient fill keep latex shadows soft.
                float diffuse = clamp((dot(normal, light) + 0.65) / 1.65, 0.0, 1.0);
                float facing = max(dot(normal, -ray), 0.0);
                vec3 halfway = normalize(light - ray);
                float specular = pow(max(dot(normal, halfway), 0.0), 5.0);
                vec3 base = vec3(0.70, 0.68, 0.71);
                vec3 rgb = base * (0.72 + 0.16 * diffuse + 0.08 * facing);
                // Bright, broad reflections from large lights, tinted by the rubber.
                rgb += mix(base, vec3(1.0), 0.55) * 0.24 * specular;
                vec3 fill = normalize(-ray + vec3(-0.25, -0.55, 0.0));
                rgb += mix(base, vec3(1.0), 0.40) * 0.16
                     * pow(max(dot(normal, fill), 0.0), 7.0);
                // Gentle nearby, gradually disappearing into black in the distance.
                // Exponential-squared fog has no visible cutoff or drawn lines.
                float fogDepth = fogDensity * t;
                rgb *= exp(-fogDepth * fogDepth);
                return vec4(rgb, 1.0) * color;
            }
        }
        // Advance through the closest cell face (ties resolve next iteration).
        if (next.x <= next.y && next.x <= next.z) {
            cell.x += stepDir.x;
            next.x += delta.x;
        } else if (next.y <= next.z) {
            cell.y += stepDir.y;
            next.y += delta.y;
        } else {
            cell.z += stepDir.z;
            next.z += delta.z;
        }
        entry = leave;
    }
    return vec4(0.0, 0.0, 0.0, 1.0) * color;
}
