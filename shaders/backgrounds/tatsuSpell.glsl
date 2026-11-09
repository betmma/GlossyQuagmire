extern Image history;
extern vec2 origin;
extern float cycle;
extern float extent;
extern float cutAngle;
extern float slide;
extern float seams;
extern bool initial;
extern float viewRotation;
extern float viewZoom;
const float N=8.0;
const float PI = 3.141592653589793;
const float WEDGE = PI*2/N;

vec3 hsv2rgb(vec3 c) {
    vec3 p = abs(fract(c.xxx + vec3(0,2,1)/3.0)*6.0 - 3.0);
    return c.z * mix(vec3(1.0), clamp(p-1.0, 0.0, 1.0), c.y);
}

vec3 freshColor(vec2 p) {
    float angle = atan(p.y, p.x);
    float index = mod(floor((angle-cutAngle) / WEDGE+(cycle==0.0?0.0:0.5)), N);
    vec3 hsv=vec3(0.5+index/N*0.0333+sin(dot(p,p)/10000.0)*0.1+cycle*0.003,0.5,0.5);
    return hsv2rgb(hsv);
}

// Find the source point in an infinite, rigidly translated wedge.
// A negative edge means the point lies in the newly opened central hole.
float sourcePoint(vec2 p, float rotation, float distance, out vec2 source) {
    for (int i = 0; i < 8; i++) {
        float angle = rotation + (float(i) + 0.5) * WEDGE;
        vec2 axis = vec2(cos(angle), sin(angle));
        vec2 tangent = vec2(-axis.y, axis.x);
        vec2 q = p - distance * tangent;
        float inside = dot(q, axis) * sin(WEDGE * 0.5)
                     - abs(dot(q, tangent)) * cos(WEDGE * 0.5);
        if (inside >= 0.0) {
            source = q;
            return inside;
        }
    }
    source = p;
    return -1.0;
}

vec3 previousColor(vec2 p) {
    vec2 uv = p / extent + 0.5;
    // Continue the original angular colour field beyond the finite canvas.
    float inset = 0.5 / extent;
    if (any(lessThan(uv, vec2(inset))) || any(greaterThan(uv, vec2(1.0 - inset))))
        return freshColor(p);
    vec3 rgb = Texel(history, uv).rgb;
    return rgb;
}

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 pixel) {
    // Inverse camera transform; simulation canvas passes use identity.
    vec2 screen = (pixel - origin) / viewZoom;
    float c = cos(viewRotation), s = sin(viewRotation);
    vec2 p = vec2(c * screen.x + s * screen.y, -s * screen.x + c * screen.y);
    if (max(abs(p.x), abs(p.y)) > extent * 0.5) return vec4(0.0);
    vec3 rgb = freshColor(p);
    if (initial) return vec4(rgb, 1.0) * color;
    vec2 source;
    float edge = sourcePoint(p, cutAngle, slide, source);
    if (edge >= 0.0) rgb = previousColor(source);
    // Only current cutting edges get a seam; old colour boundaries do not.
    float line = edge >= 0.0 ? 1.0 - smoothstep(0.0, 5.0, edge) : 0.0;
    rgb *= 1.0 - 0.06 * seams * line;
    return vec4(rgb, 1.0) * color;
}
