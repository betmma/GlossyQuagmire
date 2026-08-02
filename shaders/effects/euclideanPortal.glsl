uniform vec2 screenCenter;
uniform int numSegments;
uniform vec2 pos1s[16];
uniform vec2 pos2s[16];
uniform float signs[16];
uniform int linkeds[16];
uniform float range;

float cross2(vec2 a, vec2 b) {
    return a.x * b.y - a.y * b.x;
}

vec2 leftNormal(vec2 direction) {
    return vec2(-direction.y, direction.x);
}

// WebGL 1 only guarantees uniform-array indexing with constant loop indexes.
// Route data-dependent lookups through fixed loops instead of indexing an
// array directly with hitIndex or linkedIndex.
vec2 segmentPos1(int wantedIndex) {
    vec2 result = vec2(0.0);
    for(int index=0; index<16; index++) {
        if(index == wantedIndex) {
            result = pos1s[index];
            break;
        }
    }
    return result;
}

vec2 segmentPos2(int wantedIndex) {
    vec2 result = vec2(0.0);
    for(int index=0; index<16; index++) {
        if(index == wantedIndex) {
            result = pos2s[index];
            break;
        }
    }
    return result;
}

float segmentSign(int wantedIndex) {
    float result = 1.0;
    for(int index=0; index<16; index++) {
        if(index == wantedIndex) {
            result = signs[index];
            break;
        }
    }
    return result;
}

int linkedSegment(int wantedIndex) {
    int result = 0;
    for(int index=0; index<16; index++) {
        if(index == wantedIndex) {
            result = linkeds[index] - 1;
            break;
        }
    }
    return result;
}

bool insideTexture(vec2 point) {
    return point.x >= 0.0 && point.y >= 0.0
        && point.x < love_ScreenSize.x && point.y < love_ScreenSize.y;
}

vec4 sampleScreen(Image tex, vec2 point) {
    if(!insideTexture(point)) {
        return vec4(0.0);
    }
    return Texel(tex, point / love_ScreenSize.xy);
}

vec4 alphaOver(vec4 bottom, vec4 top) {
    // The offscreen canvas is rendered with LÖVE's alpha-multiply mode, so
    // sampled RGB is already premultiplied by alpha.
    return top + bottom * (1.0 - top.a);
}

vec4 effect(vec4 color, Image tex, vec2 textureCoords, vec2 screenCoords) {
    vec2 rayStart = screenCenter;
    vec2 rayEnd = screenCoords;
    vec4 exceedingColor = vec4(0.0);

    // A fixed upper bound is required by WebGL. Breaking keeps the effective
    // loop conditional and also prevents cyclic portal layouts from hanging.
    for(int iteration=0; iteration<32; iteration++) {
        vec2 ray = rayEnd - rayStart;
        float rayLength = length(ray);
        if(rayLength <= 0.000001) {
            break;
        }

        int hitIndex = -1;
        float hitT = 2.0;
        float hitU = 0.0;

        for(int segmentIndex=0; segmentIndex<16; segmentIndex++) {
            if(segmentIndex >= numSegments) {
                break;
            }

            vec2 portalStart = pos1s[segmentIndex];
            vec2 portalLine = pos2s[segmentIndex] - portalStart;
            float denominator = cross2(ray, portalLine);
            if(abs(denominator) <= 0.000001) {
                continue;
            }

            float startSide = cross2(portalLine, rayStart - portalStart) * signs[segmentIndex];
            float endSide = cross2(portalLine, rayEnd - portalStart) * signs[segmentIndex];
            if(startSide < -0.000001 || endSide >= -0.000001) {
                continue;
            }

            vec2 portalOffset = portalStart - rayStart;
            float rayT = cross2(portalOffset, portalLine) / denominator;
            float portalT = cross2(portalOffset, ray) / denominator;
            if(rayT > 0.000001 && rayT <= 1.0
                && portalT >= 0.0 && portalT <= 1.0
                && rayT < hitT) {
                hitIndex = segmentIndex;
                hitT = rayT;
                hitU = portalT;
            }
        }

        if(hitIndex < 0) {
            break;
        }

        vec2 oldRayEnd = rayEnd;
        vec2 hitPoint = rayStart + ray * hitT;
        float remainingDistance = rayLength * (1.0 - hitT);

        // Objects are teleported by their centers. While a center is within
        // Portal.range, retain pixels which extend just beyond the entrance.
        if(remainingDistance < range) {
            exceedingColor = alphaOver(exceedingColor,sampleScreen(tex,oldRayEnd));
        }

        int linkedIndex = linkedSegment(hitIndex);
        if(linkedIndex < 0 || linkedIndex >= numSegments) {
            break;
        }

        vec2 inputStart = segmentPos1(hitIndex);
        vec2 inputLine = segmentPos2(hitIndex) - inputStart;
        vec2 outputStart = segmentPos1(linkedIndex);
        vec2 outputEnd = segmentPos2(linkedIndex);
        vec2 outputLine = outputEnd - outputStart;
        float inputLength = length(inputLine);
        float outputLength = length(outputLine);
        if(inputLength <= 0.000001 || outputLength <= 0.000001) {
            break;
        }

        vec2 inputTangent = inputLine / inputLength;
        vec2 outputTangent = outputLine / outputLength;
        float inputSign = segmentSign(hitIndex);
        float outputSign = segmentSign(linkedIndex);
        vec2 inputOutward = -inputSign * leftNormal(inputTangent);
        vec2 outputOutward = outputSign * leftNormal(outputTangent);
        vec2 rayDirection = ray / rayLength;

        // Portal movement rotates the entrance's outward normal onto the
        // linked portal's inward-facing normal. The tangent coefficient makes
        // this a rotation for either combination of segment signs.
        float tangentCoefficient = -inputSign * outputSign;
        vec2 outputDirection =
            outputTangent * dot(rayDirection,inputTangent) * tangentCoefficient
            + outputOutward * dot(rayDirection,inputOutward);

        vec2 linkedPoint = mix(outputStart,outputEnd,hitU);
        float zoom = outputLength / inputLength;
        rayStart = linkedPoint;
        rayEnd = linkedPoint + outputDirection * remainingDistance * zoom;
    }

    vec4 portalColor = sampleScreen(tex,rayEnd);
    return alphaOver(portalColor,exceedingColor) * color;
}
