extern vec2 screenCenter;
extern float time;

const float PI = 3.141592653589793;
const float SECTOR = PI / 4.0;
const float RING = 0.58;
const float SLOPE = RING / PI;

float ink(float distance, float aa) {
    return 1.0 - smoothstep(-aa, aa, distance);
}

vec4 effect(vec4 color, Image tex, vec2 textureCoords, vec2 screenCoords) {
    vec2 p = (screenCoords - screenCenter) / 240.0;
    float radius = length(p);
    float angle = radius > 0.00001 ? atan(p.y, p.x) : 0.0;
    // Complex power in log-polar space: one turn advances exactly two
    // alternating bands, so the atan branch cut joins the same artwork.
    // Subtracting time before the transform makes this a continuous zoom.
    float logRadius = log(max(radius, 0.00001)) - time * 0.14;
    float u = logRadius + SLOPE * angle;
    float v = angle - SLOPE * logRadius;
    float face = floor((v + SECTOR * 0.5) / SECTOR);
    float localAngle = v - face * SECTOR;
    float octagon = u + log(cos(localAngle));
    float band = floor(octagon / RING);
    float parity = mod(band, 2.0);
    float depth = (exp(mod(octagon, RING)) - 1.0) / (exp(RING) - 1.0);
    float side = tan(localAngle) / tan(SECTOR * 0.5);

    // Two trigrams or three hexagrams per octagon face. All strokes are
    // analytic rectangles; no reference image or texture is sampled.
    float count = mix(2.0, 3.0, parity);
    float slot = (side * 0.5 + 0.5) * count;
    float column = floor(slot);
    float x = fract(slot) - 0.5;
    float rows = mix(3.0, 6.0, parity);
    float y = (depth - 0.20) / 0.60 * rows;
    float row = clamp(floor(y), 0.0, rows - 1.0);
    float symbol = mod(mod(face, 8.0) * 7.0 + column * 13.0 + parity * 19.0, 64.0);
    float broken = mod(floor(symbol / exp2(row)), 2.0);
    // Estimate footprints before wrapping: derivatives of fract/mod would
    // produce false wide edges at band boundaries and the angular seam.
    float footprint = (1.0 + SLOPE) / (240.0 * max(radius, 0.00001));
    float aaDepth = footprint * exp(mod(octagon, RING)) / (exp(RING) - 1.0);
    float aaX = footprint * (1.0 + pow(tan(localAngle), 2.0))
              / tan(SECTOR * 0.5) * count * 0.5;
    float aaY = aaDepth * rows / 0.60;
    float stroke = ink(abs(x) - 0.34, aaX)
                 * ink(abs(y - row - 0.5) - 0.19, aaY);
    stroke *= mix(1.0, smoothstep(0.075 - aaX, 0.075 + aaX, abs(x)), broken);

    float rim = ink(min(depth, 1.0 - depth) - 0.018, aaDepth);
    float base = mix(0.025, 0.16, parity);
    float shade = mix(base, 0.25, rim);
    // Keep the white linework subdued enough for bullets to read clearly.
    shade = mix(shade, 0.48, stroke);
    // Subpixel repetitions converge to a quiet center instead of flickering.
    float detail = smoothstep(0.012, 0.045, radius);
    shade = mix(0.09, shade, detail);
    return vec4(vec3(shade), 1.0) * color;
}
