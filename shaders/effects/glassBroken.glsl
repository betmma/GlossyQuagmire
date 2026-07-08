uniform float progress;
uniform float seed;

const float SHARD_SCALE = 13.8;

float saturate(float x) {
    return clamp(x, 0.0, 1.0);
}

vec2 hash22(vec2 p) {
    vec2 q = vec2(dot(p, vec2(269.5, 183.3)), dot(p, vec2(113.5, 271.9)));
    return fract(sin(q) * (43758.5453123+seed));
}

vec2 rotate2(vec2 p, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return vec2(p.x * c - p.y * s, p.x * s + p.y * c);
}

vec2 shardPoint(vec2 cell) {
    return cell + hash22(cell) * 0.72 + vec2(0.14, 0.14);
}

vec2 shardCenter(vec2 cell) {
    float aspect = love_ScreenSize.x / love_ScreenSize.y;
    vec2 point = shardPoint(cell);
    return vec2(point.x / (SHARD_SCALE * aspect), point.y / SHARD_SCALE);
}

vec2 shardMotion(vec2 center, vec2 cell, float fallT) {
    vec2 rnd = hash22(cell + vec2(8.31, 2.17));
    vec2 scatter;
    scatter.x = (rnd.x - 0.5) * 0.52 + (center.x - 0.5) * 0.24;
    scatter.y = 0.30 + rnd.y * 0.42 + center.y * 0.34;

    vec2 motion;
    motion.x = scatter.x * fallT;
    motion.y = scatter.y * fallT * fallT;
    return motion;
}

float shardAngle(vec2 cell, float fallT) {
    vec2 rnd = hash22(cell + vec2(8.31, 2.17));
    return (rnd.x - 0.5) * 3.55 * fallT;
}

float shardMargin(vec2 uv, vec2 cell) {
    if(uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        return -100.0;
    }

    float aspect = love_ScreenSize.x / love_ScreenSize.y;
    vec2 p = vec2(uv.x * aspect, uv.y) * SHARD_SCALE;
    vec2 ownPoint = shardPoint(cell);
    float ownDist = distance(p, ownPoint);
    float otherDist = 9999.0;

    for(int gy=0; gy<3; gy++) {
        for(int gx=0; gx<3; gx++) {
            if(gx != 1 || gy != 1) {
                vec2 otherCell = cell + vec2(float(gx) - 1.0, float(gy) - 1.0);
                vec2 otherPoint = shardPoint(otherCell);
                float d = distance(p, otherPoint);

                if(d < otherDist) {
                    otherDist = d;
                }
            }
        }
    }

    return otherDist - ownDist;
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    float p = saturate(progress);
    vec2 uv = screen_coords.xy / love_ScreenSize.xy;
    vec4 base = Texel(tex, uv) * color;

    float edgeT = smoothstep(0.00, 0.18, p);
    float fallT = smoothstep(0.00, 1.00, p);
    float pieceFade = 1.0 - smoothstep(0.72, 1.00, p);
    float behindFade = smoothstep(0.34, 0.82, p);

    float aspect = love_ScreenSize.x / love_ScreenSize.y;
    vec2 gridUv = vec2(uv.x * aspect, uv.y) * SHARD_SCALE;
    vec2 baseCell = floor(gridUv);

    float found = 0.0;
    float bestCover = 9999.0;
    float bestMargin = 0.0;
    vec2 bestSampleUv = uv;

    for(int gy=0; gy<14; gy++) {
        for(int gx=0; gx<11; gx++) {
            vec2 cell = baseCell + vec2(float(gx) - 5.0, float(gy) - 10.0);
            vec2 center = shardCenter(cell);
            vec2 movedCenter = center + shardMotion(center, cell, fallT);
            float angle = shardAngle(cell, fallT);
            vec2 sampleUv = center + rotate2(uv - movedCenter, -angle);
            float margin = shardMargin(sampleUv, cell);

            if(margin > -0.0001) {
                float cover = distance(uv, movedCenter);

                if(cover < bestCover) {
                    found = 1.0;
                    bestCover = cover;
                    bestMargin = margin;
                    bestSampleUv = sampleUv;
                }
            }
        }
    }

    vec4 piece = Texel(tex, bestSampleUv) * color;
    float pieceAlpha = found * pieceFade * piece.a;
    vec3 behind = mix(base.rgb * 0.04, base.rgb, behindFade);
    vec3 result = mix(base.rgb, behind, fallT);
    result = mix(result, piece.rgb, pieceAlpha);

    float brightEdge = 1.0 - smoothstep(0.03, 0.060, bestMargin);
    brightEdge *= found * edgeT * pieceFade;
    result = mix(result, vec3(1.0, 0.96, 0.84), brightEdge * 0.82);
    result += vec3(0.38, 0.48, 0.58) * brightEdge * 0.35;

    return vec4(clamp(result, 0.0, 1.0), base.a);
}
