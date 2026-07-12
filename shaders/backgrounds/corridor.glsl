uniform vec3 translation;
uniform float pitch;
uniform float yaw;
uniform float roll;
uniform float time;
const vec3 lightDirection = vec3(-0.42, 0.78, -0.28);

const float CORRIDOR_HALF_WIDTH = 2.15;
const float CORRIDOR_HALF_HEIGHT = 4.00;
const float BAY_LENGTH = 10.0;
const float WORLD_WRAP_LENGTH = 1600.0;
const float MAX_TRAVEL = 420.0;
const float HIT_EPSILON = 0.003;
const float SUNLIGHT_MAX_TRAVEL = 18.0;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}

float valueNoise(vec2 p) {
    vec2 cell = floor(p);
    vec2 local = fract(p);
    local = local * local * (3.0 - 2.0 * local);

    float a = hash21(cell);
    float b = hash21(cell + vec2(1.0, 0.0));
    float c = hash21(cell + vec2(0.0, 1.0));
    float d = hash21(cell + vec2(1.0, 1.0));
    return mix(mix(a, b, local.x), mix(c, d, local.x), local.y);
}

float localBayZ(float z) {
    return mod(z + BAY_LENGTH * 0.5, BAY_LENGTH) - BAY_LENGTH * 0.5;
}

float bayIndex(float z) {
    return floor((z + BAY_LENGTH * 0.5) / BAY_LENGTH);
}

bool insideRectangle(vec2 point, vec2 halfSize) {
    return abs(point.x) < halfSize.x && abs(point.y) < halfSize.y;
}

vec3 hsvToRgb(vec3 hsv) {
    float sector = mod(hsv.x, 1.0) * 6.0;
    float chroma = hsv.z * hsv.y;
    float secondary = chroma * (1.0 - abs(mod(sector, 2.0) - 1.0));
    vec3 rgb;

    if(sector < 1.0) {
        rgb = vec3(chroma, secondary, 0.0);
    }else if(sector < 2.0) {
        rgb = vec3(secondary, chroma, 0.0);
    }else if(sector < 3.0) {
        rgb = vec3(0.0, chroma, secondary);
    }else if(sector < 4.0) {
        rgb = vec3(0.0, secondary, chroma);
    }else if(sector < 5.0) {
        rgb = vec3(secondary, 0.0, chroma);
    }else{
        rgb = vec3(chroma, 0.0, secondary);
    }

    return rgb + vec3(hsv.z - chroma);
}

vec3 rgbToHsv(vec3 rgb) {
    float maximum = max(rgb.r, max(rgb.g, rgb.b));
    float minimum = min(rgb.r, min(rgb.g, rgb.b));
    float delta = maximum - minimum;
    float hue = 0.0;

    if(delta > 0.000001) {
        if(maximum == rgb.r) {
            hue = mod((rgb.g - rgb.b) / delta, 6.0) / 6.0;
        }else if(maximum == rgb.g) {
            hue = ((rgb.b - rgb.r) / delta + 2.0) / 6.0;
        }else{
            hue = ((rgb.r - rgb.g) / delta + 4.0) / 6.0;
        }
    }

    float saturation = 0.0;
    if(maximum > 0.000001) {
        saturation = delta / maximum;
    }
    return vec3(mod(hue, 1.0), saturation, maximum);
}

vec3 applyWorldState(vec3 baseColor, bool reflected, float hueShift) {
    if(!reflected) {
        float gray = dot(baseColor, vec3(0.299, 0.587, 0.114));
        return mix(vec3(gray), baseColor, 0.32);
    }

    vec3 hsv = rgbToHsv(max(baseColor, vec3(0.0001)));
    hsv.x = mod(hsv.x + hueShift, 1.0);
    hsv.y = max(hsv.y, 0.72);
    hsv.z = min(hsv.z * 1.24 + 0.035, 1.0);
    return hsvToRgb(hsv);
}

vec3 rotatePitch(vec3 direction, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return vec3(direction.x, direction.y * c - direction.z * s, direction.y * s + direction.z * c);
}

vec3 rotateYaw(vec3 direction, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return vec3(direction.x * c + direction.z * s, direction.y, -direction.x * s + direction.z * c);
}

vec3 rotateRoll(vec3 direction, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return vec3(direction.x * c - direction.y * s, direction.x * s + direction.y * c, direction.z);
}

vec4 corridorIntersection(vec3 point, vec3 rayDirection) {
    const float NO_INTERSECTION = 1000000.0;
    float nearestTravel = NO_INTERSECTION;
    vec3 nearestNormal = vec3(0.0);

    if(abs(rayDirection.x) > 0.000001) {
        float wallX = rayDirection.x > 0.0 ? CORRIDOR_HALF_WIDTH : -CORRIDOR_HALF_WIDTH;
        float wallTravel = (wallX - point.x) / rayDirection.x;
        if(wallTravel >= 0.0 && wallTravel < nearestTravel) {
            nearestTravel = wallTravel;
            nearestNormal = rayDirection.x > 0.0
                ? vec3(-1.0, 0.0, 0.0)
                : vec3(1.0, 0.0, 0.0);
        }
    }

    if(abs(rayDirection.y) > 0.000001) {
        float wallY = rayDirection.y > 0.0 ? CORRIDOR_HALF_HEIGHT : -CORRIDOR_HALF_HEIGHT;
        float wallTravel = (wallY - point.y) / rayDirection.y;
        if(wallTravel >= 0.0 && wallTravel < nearestTravel) {
            nearestTravel = wallTravel;
            nearestNormal = rayDirection.y > 0.0
                ? vec3(0.0, -1.0, 0.0)
                : vec3(0.0, 1.0, 0.0);
        }
    }

    return vec4(nearestNormal, nearestTravel);
}

vec2 leftWindowUv(vec3 point) {
    return vec2((localBayZ(point.z) + 2.45) / 1.85, point.y / 1.72);
}

bool leftWindow(vec3 point) {
    return insideRectangle(vec2(localBayZ(point.z) + 2.45, point.y), vec2(1.85, 1.72));
}

bool leftMirrorOuter(vec3 point) {
    return insideRectangle(vec2(localBayZ(point.z) - 2.35, point.y), vec2(2.05, 2.72));
}

bool leftMirrorInner(vec3 point) {
    return insideRectangle(vec2(localBayZ(point.z) - 2.35, point.y), vec2(1.91, 2.58));
}

bool rightMirrorOuter(vec3 point) {
    return insideRectangle(vec2(localBayZ(point.z) + 2.35, point.y), vec2(2.05, 2.72));
}

bool rightMirrorInner(vec3 point) {
    return insideRectangle(vec2(localBayZ(point.z) + 2.35, point.y), vec2(1.91, 2.58));
}

bool rightPictureOuter(vec3 point) {
    return insideRectangle(vec2(localBayZ(point.z) - 2.25, point.y), vec2(1.48, 1.45));
}

bool rightPictureInner(vec3 point) {
    return insideRectangle(vec2(localBayZ(point.z) - 2.25, point.y), vec2(1.15, 1.12));
}

bool mirrorInterior(vec3 point, float wallSide) {
    if(wallSide < 0.0) {
        return leftMirrorInner(point);
    }
    return rightMirrorInner(point);
}

vec3 wallNormalFromSlopes(float wallSide, float slopeY, float slopeZ) {
    return normalize(vec3(-wallSide, slopeY, slopeZ));
}

vec2 mirrorLocalCoordinates(vec3 point, float wallSide) {
    float mirrorCenterZ = -2.35;
    if(wallSide < 0.0) {
        mirrorCenterZ = 2.35;
    }
    return vec2(localBayZ(point.z) - mirrorCenterZ, point.y);
}

vec4 mirrorBorderNormalMap(vec3 point, float wallSide) {
    vec2 local = mirrorLocalCoordinates(point, wallSide);
    vec2 outerHalfSize = vec2(2.05, 1.72);
    vec2 innerHalfSize = vec2(1.91, 1.58);

    float sideHalfWidth = (outerHalfSize.x - innerHalfSize.x) * 0.5;
    float capHalfWidth = (outerHalfSize.y - innerHalfSize.y) * 0.5;
    float sideCenter = (outerHalfSize.x + innerHalfSize.x) * 0.5;
    float capCenter = (outerHalfSize.y + innerHalfSize.y) * 0.5;

    float sideOffset = abs(local.x) - sideCenter;
    float capOffset = abs(local.y) - capCenter;
    float sideProfile = 1.0 - smoothstep(sideHalfWidth * 0.72, sideHalfWidth, abs(sideOffset));
    float capProfile = 1.0 - smoothstep(capHalfWidth * 0.72, capHalfWidth, abs(capOffset));

    float sideSlope = clamp(sideOffset / sideHalfWidth, -1.0, 1.0) * sign(local.x) * sideProfile;
    float capSlope = clamp(capOffset / capHalfWidth, -1.0, 1.0) * sign(local.y) * capProfile;
    vec3 borderNormal = wallNormalFromSlopes(wallSide, -capSlope * 0.68, -sideSlope * 0.68);
    return vec4(borderNormal, max(sideProfile, capProfile));
}

vec2 pictureFrameLocalCoordinates(vec3 point) {
    return vec2(localBayZ(point.z) - 2.25, point.y);
}

vec4 pictureFrameCoordinates(vec2 local) {
    vec2 outerHalfSize = vec2(1.48, 1.45);
    vec2 innerHalfSize = vec2(1.15, 1.12);
    vec2 frameWidth = outerHalfSize - innerHalfSize;

    float sideAmount = abs(local.x) - innerHalfSize.x;
    float capAmount = abs(local.y) - innerHalfSize.y;
    float sideWeight = smoothstep(-0.035, 0.035, sideAmount - capAmount);
    float capWeight = 1.0 - sideWeight;

    float sideAcross = clamp(sideAmount / frameWidth.x, 0.0, 1.0);
    float capAcross = clamp(capAmount / frameWidth.y, 0.0, 1.0);
    float across = mix(capAcross, sideAcross, sideWeight);
    float along = mix(local.x, local.y, sideWeight);
    return vec4(across, along, sideWeight, capWeight);
}

float pictureFrameRidge(float coordinate, float center, float halfWidth) {
    return 1.0 - smoothstep(halfWidth * 0.45, halfWidth, abs(coordinate - center));
}

float pictureFrameOrnament(vec2 local) {
    vec4 coordinates = pictureFrameCoordinates(local);
    float across = coordinates.x;
    float along = coordinates.y;

    float repeated = fract(along * 2.65 + 0.5) - 0.5;
    vec2 medallionCoordinates = vec2(repeated * 2.85, (across - 0.52) * 4.80);
    float medallion = 1.0 - smoothstep(0.48, 0.78, length(medallionCoordinates));

    float beadWave = max(0.5 + 0.5 * cos(along * 31.0), 0.0);
    float beads = pow(beadWave, 7.0) * pictureFrameRidge(across, 0.52, 0.12);

    float sideLeaf = 1.0 - smoothstep(0.13, 0.30, abs(abs(repeated) - 0.20));
    sideLeaf *= pictureFrameRidge(across, 0.52, 0.18);
    return clamp(medallion * 0.78 + beads * 0.48 + sideLeaf * 0.26, 0.0, 1.0);
}

float pictureFrameHeight(vec2 local) {
    vec4 coordinates = pictureFrameCoordinates(local);
    float across = coordinates.x;

    float edgePlate = smoothstep(0.0, 0.12, across);
    edgePlate *= 1.0 - smoothstep(0.88, 1.0, across);

    float innerLip = pictureFrameRidge(across, 0.16, 0.095);
    float innerGroove = pictureFrameRidge(across, 0.29, 0.040);
    float centerCrown = pictureFrameRidge(across, 0.52, 0.24);
    float outerGroove = pictureFrameRidge(across, 0.75, 0.042);
    float outerLip = pictureFrameRidge(across, 0.86, 0.095);
    float ornament = pictureFrameOrnament(local);

    float height = edgePlate * 0.115;
    height += innerLip * 0.060;
    height -= innerGroove * 0.028;
    height += centerCrown * 0.075;
    height -= outerGroove * 0.026;
    height += outerLip * 0.052;
    height += ornament * 0.030;
    return height;
}

vec4 pictureFrameNormalPattern(vec3 point, float wallSide) {
    vec2 local = pictureFrameLocalCoordinates(point);
    float sampleDistance = 0.004;

    float heightYPositive = pictureFrameHeight(local + vec2(0.0, sampleDistance));
    float heightYNegative = pictureFrameHeight(local - vec2(0.0, sampleDistance));
    float heightZPositive = pictureFrameHeight(local + vec2(sampleDistance, 0.0));
    float heightZNegative = pictureFrameHeight(local - vec2(sampleDistance, 0.0));

    float slopeY = -(heightYPositive - heightYNegative) / (sampleDistance * 2.0);
    float slopeZ = -(heightZPositive - heightZNegative) / (sampleDistance * 2.0);
    vec3 frameNormal = wallNormalFromSlopes(wallSide, slopeY * 0.82, slopeZ * 0.82);
    float ornament = pictureFrameOrnament(local);
    return vec4(frameNormal, ornament);
}

float mirrorHueShift(vec3 point, float wallSide) {
    float sequence = bayIndex(point.z) * 2.0;
    if(wallSide < 0.0) {
        sequence += 1.0;
    }
    float profile = mod(sequence, 4.0);

    if(profile < 0.5) {
        return 0.08;
    }else if(profile < 1.5) {
        return 0.31;
    }else if(profile < 2.5) {
        return 0.57;
    }
    return 0.82;
}

vec3 windowScene(vec3 point) {
    vec2 windowUv = leftWindowUv(point);
    float vertical = clamp(windowUv.y * 0.5 + 0.5, 0.0, 1.0);
    vec3 daylight = mix(vec3(1.28, 1.10, 0.82), vec3(1.02, 1.12, 1.30), vertical);
    float bloom = 1.0 - smoothstep(0.0, 1.18, length(windowUv * vec2(0.76, 0.92)));
    return daylight * (1.12 + bloom * 0.34);
}

float nearestThreeBarOffset(float coordinate, float spacing) {
    float nearestIndex = floor(coordinate / spacing + 0.5);
    nearestIndex = clamp(nearestIndex, -1.0, 1.0);
    return coordinate - nearestIndex * spacing;
}

vec4 windowGrillNormalTransparency(vec3 point) {
    vec2 windowUv = leftWindowUv(point);
    float verticalOffset = nearestThreeBarOffset(windowUv.x, 0.52);
    float horizontalOffset = nearestThreeBarOffset(windowUv.y, 0.46);
    float barRadius = 0.034;
    float softEdge = 0.016;
    float borderWidth = 0.125;

    float verticalOpacity = 1.0 - smoothstep(barRadius, barRadius + softEdge, abs(verticalOffset));
    float horizontalOpacity = 1.0 - smoothstep(barRadius, barRadius + softEdge, abs(horizontalOffset));

    float sideBorderDistance = 1.0 - abs(windowUv.x);
    float capBorderDistance = 1.0 - abs(windowUv.y);
    float sideBorderOpacity = 1.0 - smoothstep(borderWidth - softEdge, borderWidth + softEdge, sideBorderDistance);
    float capBorderOpacity = 1.0 - smoothstep(borderWidth - softEdge, borderWidth + softEdge, capBorderDistance);
    float borderOpacity = max(sideBorderOpacity, capBorderOpacity);

    float verticalPhase = clamp(verticalOffset / barRadius, -1.0, 1.0) * 3.14159265;
    float horizontalPhase = clamp(horizontalOffset / barRadius, -1.0, 1.0) * 3.14159265;
    float verticalSlope = sin(verticalPhase) * verticalOpacity;
    float horizontalSlope = sin(horizontalPhase) * horizontalOpacity;

    float sideBorderOffset = sideBorderDistance - borderWidth * 0.5;
    float capBorderOffset = capBorderDistance - borderWidth * 0.5;
    float sideBorderPhase = clamp(sideBorderOffset / (borderWidth * 0.5), -1.0, 1.0) * 3.14159265;
    float capBorderPhase = clamp(capBorderOffset / (borderWidth * 0.5), -1.0, 1.0) * 3.14159265;
    float sideBorderSlope = sin(sideBorderPhase) * sideBorderOpacity * sign(windowUv.x);
    float capBorderSlope = sin(capBorderPhase) * capBorderOpacity * sign(windowUv.y);

    float combinedVerticalSlope = horizontalSlope + capBorderSlope * 0.92;
    float combinedHorizontalSlope = verticalSlope + sideBorderSlope * 0.92;
    vec3 grillNormal = normalize(vec3(1.0, combinedVerticalSlope * 0.88, combinedHorizontalSlope * 0.88));
    float grillOpacity = max(max(verticalOpacity, horizontalOpacity), borderOpacity);
    float transparency = 1.0 - grillOpacity;
    return vec4(grillNormal, transparency);
}

vec3 shadeWindow(vec3 point, vec3 rayDirection) {
    vec3 daylight = windowScene(point);
    vec4 grillSample = windowGrillNormalTransparency(point);
    vec3 grillNormal = grillSample.xyz;
    vec3 incomingLightDirection = normalize(-lightDirection);
    float diffuse = 0.46 + max(dot(grillNormal, incomingLightDirection), 0.0) * 0.74;
    float specular = pow(max(dot(reflect(-incomingLightDirection, grillNormal), -rayDirection), 0.0), 24.0);

    float edgeShade = 1.0 - grillNormal.x;
    vec3 grillColor = vec3(0.18, 0.21, 0.21) * (0.90 + diffuse * 0.72);
    grillColor += vec3(0.72, 0.80, 0.78) * specular * 0.82;
    grillColor += daylight * 0.055;
    grillColor *= 1.0 - edgeShade * 0.16;
    return mix(grillColor, daylight, grillSample.w);
}


vec3 shadeMirrorBorder(vec3 point, vec3 rayDirection, float wallSide) {
    vec4 borderSample = mirrorBorderNormalMap(point, wallSide);
    vec3 borderNormal = borderSample.xyz;
    vec3 lightVector = normalize(-lightDirection);
    vec3 viewVector = -rayDirection;
    vec3 halfVector = normalize(lightVector + viewVector);

    float diffuse = 0.34 + max(dot(borderNormal, lightVector), 0.0) * 0.92;
    float specular = pow(max(dot(borderNormal, halfVector), 0.0), 52.0);
    float edgeGlint = pow(1.0 - abs(dot(borderNormal, viewVector)), 3.0);
    vec3 gold = mix(vec3(0.34, 0.19, 0.045), vec3(0.88, 0.64, 0.18), diffuse);
    gold += vec3(1.12, 0.92, 0.42) * specular * 1.15;
    gold += vec3(0.42, 0.25, 0.060) * edgeGlint * borderSample.w;
    return gold;
}

vec3 shadePictureFrame(vec3 point, vec3 rayDirection, float wallSide) {
    vec2 local = pictureFrameLocalCoordinates(point);
    vec4 coordinates = pictureFrameCoordinates(local);
    vec4 frameSample = pictureFrameNormalPattern(point, wallSide);
    vec3 frameNormal = frameSample.xyz;
    vec3 lightVector = normalize(-lightDirection);
    vec3 viewVector = -rayDirection;
    vec3 halfVector = normalize(lightVector + viewVector);

    float diffuse = 0.42 + max(dot(frameNormal, lightVector), 0.0) * 0.88;
    float specular = pow(max(dot(frameNormal, halfVector), 0.0), 38.0);
    float edgeGlint = pow(1.0 - abs(dot(frameNormal, viewVector)), 3.0);
    float across = coordinates.x;
    float ornament = frameSample.w;

    float innerRail = pictureFrameRidge(across, 0.16, 0.095);
    float centerRail = pictureFrameRidge(across, 0.52, 0.24);
    float outerRail = pictureFrameRidge(across, 0.86, 0.095);
    float groove = max(pictureFrameRidge(across, 0.29, 0.040), pictureFrameRidge(across, 0.75, 0.042));

    float grain = valueNoise(vec2(coordinates.y * 3.2, across * 15.0 + local.x * 0.35));
    vec3 solidWood = vec3(0.41, 0.155, 0.040);
    vec3 frameColor = solidWood * (0.91 + grain * 0.16);
    frameColor *= 0.50 + diffuse * 0.72;
    frameColor *= 1.0 - groove * 0.18;

    float raisedMolding = max(max(innerRail, outerRail), centerRail * 0.72);
    frameColor += vec3(0.24, 0.085, 0.018) * raisedMolding * diffuse * 0.34;
    frameColor += vec3(0.36, 0.14, 0.030) * ornament * diffuse * 0.42;
    frameColor += vec3(1.00, 0.62, 0.20) * specular * (0.40 + raisedMolding * 0.44 + ornament * 0.30);
    frameColor += vec3(0.24, 0.075, 0.012) * edgeGlint * 0.28;
    return frameColor;
}

float traceSecondarySunlightRay(vec3 point, vec3 surfaceNormal, vec3 rayDirection) {
    float illumination = max(dot(surfaceNormal, rayDirection), 0.0);
    if(illumination <= 0.0) {
        return 0.0;
    }

    vec3 rayPoint = point + surfaceNormal * 0.018;
    vec4 intersection = corridorIntersection(rayPoint, rayDirection);
    if(intersection.w > SUNLIGHT_MAX_TRAVEL) {
        return 0.0;
    }

    rayPoint += rayDirection * intersection.w;
    if(intersection.x > 0.5 && leftWindow(rayPoint)) {
        vec4 grillSample = windowGrillNormalTransparency(rayPoint);
        return illumination * grillSample.w;
    }
    return 0.0;
}

vec3 secondarySunlightRay(vec3 point, vec3 surfaceNormal) {
    const float TWO_PI = 6.28318530718;
    const float CHANNEL_ANGLE_OFFSET = TWO_PI / 3.0;
    const float ROTATION_SPEED = 0.65;
    const float ROTATION_RADIUS = 0.12;

    vec3 constantDirection = normalize(lightDirection);

    // Construct an orthonormal basis spanning the plane perpendicular to
    // the constant direction, then rotate inside that plane over time.
    vec3 referenceAxis = abs(constantDirection.y) < 0.999
        ? vec3(0.0, 1.0, 0.0)
        : vec3(1.0, 0.0, 0.0);
    vec3 perpendicularU = normalize(cross(constantDirection, referenceAxis));
    vec3 perpendicularV = normalize(cross(constantDirection, perpendicularU));

    float baseAngle = time * ROTATION_SPEED +point.z/10.0;

    float redAngle = baseAngle;
    float greenAngle = baseAngle + CHANNEL_ANGLE_OFFSET;
    float blueAngle = baseAngle + CHANNEL_ANGLE_OFFSET * 2.0;

    vec3 redRotation = ROTATION_RADIUS * (
        perpendicularU * cos(redAngle) + perpendicularV * sin(redAngle)
    );
    vec3 greenRotation = ROTATION_RADIUS * (
        perpendicularU * cos(greenAngle) + perpendicularV * sin(greenAngle)
    );
    vec3 blueRotation = ROTATION_RADIUS * (
        perpendicularU * cos(blueAngle) + perpendicularV * sin(blueAngle)
    );

    vec3 redDirection = normalize(constantDirection + redRotation);
    vec3 greenDirection = normalize(constantDirection + greenRotation);
    vec3 blueDirection = normalize(constantDirection + blueRotation);

    return vec3(
        traceSecondarySunlightRay(point, surfaceNormal, redDirection),
        traceSecondarySunlightRay(point, surfaceNormal, greenDirection),
        traceSecondarySunlightRay(point, surfaceNormal, blueDirection)
    );
}

vec3 pictureScene(vec3 point, bool reflected) {
    if(!reflected) {
        float canvasNoise = valueNoise(vec2(localBayZ(point.z), point.y) * 9.0);
        return vec3(0.030, 0.032, 0.034) * (0.84 + canvasNoise * 0.12);
    }

    vec2 pictureUv = vec2((localBayZ(point.z) - 2.25) / 1.15, point.y / 1.12);
    float wave = sin(pictureUv.x * 8.0 + sin(pictureUv.y * 5.0 - time * 0.7) + time * 0.45);
    float sweep = 0.5 + 0.5 * wave;
    float hue = mod(0.58 + pictureUv.y * 0.18 + sweep * 0.16, 1.0);
    vec3 art = hsvToRgb(vec3(hue, 0.78, 0.48 + sweep * 0.35));

    vec2 orbCenter = vec2(0.34 * sin(time * 0.23), 0.18 + 0.12 * cos(time * 0.31));
    float orb = 1.0 - smoothstep(0.19, 0.23, length(pictureUv - orbCenter));
    art = mix(art, vec3(1.0, 0.74, 0.28), orb);

    float ridge = 1.0 - smoothstep(0.0, 0.06, abs(pictureUv.y + 0.38 + 0.12 * sin(pictureUv.x * 5.0)));
    art += vec3(0.16, 0.95, 0.64) * ridge * 0.65;
    return art;
}

vec3 shadeMirrorLimit(vec3 point, float hueShift) {
    float streak = 0.5 + 0.5 * sin(point.y * 24.0 + point.z * 3.0 + time * 0.8);
    vec3 silver = mix(vec3(0.11, 0.16, 0.20), vec3(0.48, 0.58, 0.66), streak * 0.45);
    return applyWorldState(silver, true, hueShift);
}

float beveledCell(float coordinate, float cellSize, float bevelWidth) {
    float local = abs(fract(coordinate / cellSize + 0.5) - 0.5) * cellSize;
    float edgeDistance = cellSize * 0.5 - local;
    return smoothstep(0.0, bevelWidth, edgeDistance);
}

float floorPatternHeight(vec2 coordinates) {
    const float TILE_WIDTH = 0.72;
    const float TILE_LENGTH = 1.34;
    const float BEVEL_WIDTH = 0.045;

    float row = floor(coordinates.y / TILE_LENGTH + 0.5);
    float staggeredX = coordinates.x + mod(row, 2.0) * TILE_WIDTH * 0.5;
    float bevelX = beveledCell(staggeredX, TILE_WIDTH, BEVEL_WIDTH);
    float bevelZ = beveledCell(coordinates.y, TILE_LENGTH, BEVEL_WIDTH);
    float tileTop = min(bevelX, bevelZ);

    // A shallow lengthwise grain keeps the broad tile faces from looking flat.
    float grain = sin(coordinates.y * 34.0 + sin(staggeredX * 17.0) * 1.4);
    return tileTop * 0.050 + grain * tileTop * 0.0035;
}

float ceilingPatternHeight(vec2 coordinates) {
    const float PANEL_WIDTH = 1.55;
    const float PANEL_LENGTH = 2.45;
    const float MOLDING_WIDTH = 0.16;

    float xFromEdge = PANEL_WIDTH * 0.5
        - abs(fract(coordinates.x / PANEL_WIDTH + 0.5) - 0.5) * PANEL_WIDTH;
    float zFromEdge = PANEL_LENGTH * 0.5
        - abs(fract(coordinates.y / PANEL_LENGTH + 0.5) - 0.5) * PANEL_LENGTH;
    float edgeDistance = min(xFromEdge, zFromEdge);

    float outerMolding = 1.0 - smoothstep(MOLDING_WIDTH, MOLDING_WIDTH * 1.75, edgeDistance);
    float innerLip = 1.0 - smoothstep(0.025, 0.070, abs(edgeDistance - MOLDING_WIDTH * 1.85));
    float panel = smoothstep(MOLDING_WIDTH * 1.9, MOLDING_WIDTH * 2.7, edgeDistance);
    float plaster = sin(coordinates.x * 8.0 + coordinates.y * 5.0) * 0.002;
    return outerMolding * 0.090 + innerLip * 0.032 + panel * 0.012 + plaster;
}

vec4 horizontalSurfaceNormalMap(vec3 point, float normalY) {
    const float SAMPLE_DISTANCE = 0.006;
    vec2 coordinates = point.xz;
    bool floorSurface = normalY > 0.0;

    float xPositive = floorSurface
        ? floorPatternHeight(coordinates + vec2(SAMPLE_DISTANCE, 0.0))
        : ceilingPatternHeight(coordinates + vec2(SAMPLE_DISTANCE, 0.0));
    float xNegative = floorSurface
        ? floorPatternHeight(coordinates - vec2(SAMPLE_DISTANCE, 0.0))
        : ceilingPatternHeight(coordinates - vec2(SAMPLE_DISTANCE, 0.0));
    float zPositive = floorSurface
        ? floorPatternHeight(coordinates + vec2(0.0, SAMPLE_DISTANCE))
        : ceilingPatternHeight(coordinates + vec2(0.0, SAMPLE_DISTANCE));
    float zNegative = floorSurface
        ? floorPatternHeight(coordinates - vec2(0.0, SAMPLE_DISTANCE))
        : ceilingPatternHeight(coordinates - vec2(0.0, SAMPLE_DISTANCE));

    float slopeX = (xPositive - xNegative) / (SAMPLE_DISTANCE * 2.0);
    float slopeZ = (zPositive - zNegative) / (SAMPLE_DISTANCE * 2.0);
    vec3 mappedNormal = normalize(vec3(-slopeX, normalY, -slopeZ));
    float height = floorSurface
        ? floorPatternHeight(coordinates)
        : ceilingPatternHeight(coordinates);
    return vec4(mappedNormal, height);
}

vec3 shadeHorizontalPattern(vec3 baseColor, vec3 mappedNormal, vec3 rayDirection, float gloss) {
    vec3 lightVector = normalize(-lightDirection);
    vec3 viewVector = -rayDirection;
    vec3 halfVector = normalize(lightVector + viewVector);
    float diffuse = 0.46 + max(dot(mappedNormal, lightVector), 0.0) * 0.74;
    float specular = pow(max(dot(mappedNormal, halfVector), 0.0), gloss);
    return baseColor * diffuse + vec3(0.72, 0.68, 0.58) * specular * 0.24;
}

vec3 shadeSurface(vec3 point, vec3 rayDirection, vec3 normal, float travel, bool reflected, float hueShift) {
    vec3 baseColor = vec3(0.23, 0.25, 0.27);
    float grain = valueNoise(vec2(point.z * 1.7, point.y * 5.1));
    float facing = 0.56 + 0.44 * abs(dot(normal, -rayDirection));

    if(abs(normal.x) > 0.5) {
        float wallSide = point.x < 0.0 ? -1.0 : 1.0;
        baseColor = mix(vec3(0.43, 0.39, 0.33), vec3(0.56, 0.50, 0.41), grain * 0.22);

        if(wallSide < 0.0) {
            if(leftWindow(point)) {
                baseColor = shadeWindow(point, rayDirection);
                facing = 1.0;
            }else if(leftMirrorOuter(point)) {
                baseColor = shadeMirrorBorder(point, rayDirection, wallSide);
                facing = 1.0;
            }
        }else{
            if(rightPictureInner(point)) {
                baseColor = pictureScene(point, reflected);
                facing = 1.0;
            }else if(rightPictureOuter(point)) {
                baseColor = shadePictureFrame(point, rayDirection, wallSide);
                facing = 1.0;
            }else if(rightMirrorOuter(point)) {
                baseColor = shadeMirrorBorder(point, rayDirection, wallSide);
                facing = 1.0;
            }
        }
    }else if(normal.y > 0.0) {
        vec4 floorSample = horizontalSurfaceNormalMap(point, normal.y);
        float floorGrain = valueNoise(vec2(point.z * 0.72 + point.x * 0.16, point.x * 2.8));
        baseColor = mix(vec3(0.105, 0.055, 0.032), vec3(0.24, 0.13, 0.070), floorGrain * 0.38);
        float tileTop = smoothstep(0.012, 0.045, floorSample.w);
        baseColor *= mix(0.64, 1.08, tileTop);
        baseColor = shadeHorizontalPattern(baseColor, floorSample.xyz, rayDirection, 42.0);

        vec3 sunlight = secondarySunlightRay(point, floorSample.xyz);
        baseColor += sunlight * 1.22;
    }else{
        vec4 ceilingSample = horizontalSurfaceNormalMap(point, normal.y);
        float ceilingGrain = valueNoise(vec2(point.z * 0.38, point.x * 1.6));
        baseColor = mix(vec3(0.47, 0.44, 0.39), vec3(0.58, 0.53, 0.45), ceilingGrain * 0.24);
        float raisedMolding = smoothstep(0.040, 0.082, ceilingSample.w);
        baseColor *= mix(0.91, 1.07, raisedMolding);
        baseColor = shadeHorizontalPattern(baseColor, ceilingSample.xyz, rayDirection, 28.0);
    }

    baseColor *= 0.78 + 0.22 * facing;

    float fog = 1.0 - exp(-travel * 0.009);
    vec3 fogColor = reflected ? vec3(0.090, 0.155, 0.215) : vec3(0.160, 0.165, 0.172);
    baseColor = mix(baseColor, fogColor, fog * 0.68);
    return applyWorldState(baseColor, reflected, hueShift);
}

vec3 farCorridor(vec3 rayDirection, bool reflected, float hueShift) {
    float axialAlignment = pow(clamp(abs(rayDirection.z), 0.0, 1.0), 8.0);
    vec3 farColor = mix(vec3(0.135, 0.140, 0.148), vec3(0.205, 0.212, 0.222), axialAlignment);

    if(reflected) {
        farColor = mix(vec3(0.080, 0.140, 0.195), vec3(0.125, 0.225, 0.305), axialAlignment);
    }

    return applyWorldState(farColor, reflected, hueShift);
}

vec3 rayMarchCorridor(vec3 rayOrigin, vec3 rayDirection) {
    vec3 point = rayOrigin;
    float travel = 0.0;
    bool reflected = false;
    float hueShift = 0.0;
    int mirrorCount = 0;

    for(int stepIndex=0; stepIndex<21; stepIndex++) {
        vec4 intersection = corridorIntersection(point, rayDirection);
        float hitTravel = intersection.w;

        if(travel + hitTravel > MAX_TRAVEL) {
            return farCorridor(rayDirection, reflected, hueShift);
        }

        point += rayDirection * hitTravel;
        travel += hitTravel;

        vec3 normal = intersection.xyz;
        bool wallHit = abs(normal.x) > 0.5;
        float wallSide = point.x < 0.0 ? -1.0 : 1.0;

        if(wallHit && mirrorInterior(point, wallSide)) {
            if(mirrorCount < 60) {
                hueShift = mod(hueShift + mirrorHueShift(point, wallSide), 1.0);
                reflected = true;
                mirrorCount++;
                rayDirection = reflect(rayDirection, normal);
                point += normal * 0.018;
                travel += 0.018;
            }else{
                return shadeMirrorLimit(point, hueShift);
            }
        }else{
            return shadeSurface(point, rayDirection, normal, travel, reflected, hueShift);
        }
    }

    return farCorridor(rayDirection, reflected, hueShift);
}

vec4 effect(vec4 color, Image texture, vec2 textureCoords, vec2 screenCoords) {
    vec2 uv = screenCoords.xy / love_ScreenSize.xy;
    uv = uv * 2.0 - 1.0;
    uv.y = -uv.y;
    uv.x *= love_ScreenSize.x / love_ScreenSize.y;

    vec3 rayOrigin = translation + vec3(0.0, 0.0, time * 1.30);
    rayOrigin.z = mod(rayOrigin.z + WORLD_WRAP_LENGTH * 0.5, WORLD_WRAP_LENGTH) - WORLD_WRAP_LENGTH * 0.5;
    rayOrigin.x = clamp(rayOrigin.x, -CORRIDOR_HALF_WIDTH + 0.05, CORRIDOR_HALF_WIDTH - 0.05);
    rayOrigin.y = clamp(rayOrigin.y, -CORRIDOR_HALF_HEIGHT + 0.05, CORRIDOR_HALF_HEIGHT - 0.05);

    vec3 rayDirection = normalize(vec3(uv.x, uv.y, 1.28));
    rayDirection = rotateYaw(rayDirection, yaw);
    rayDirection = rotatePitch(rayDirection, pitch);
    rayDirection = rotateRoll(rayDirection, roll);
    rayDirection = normalize(rayDirection);

    vec3 fragmentColor = rayMarchCorridor(rayOrigin, rayDirection);
    float vignette = 1.0 - smoothstep(0.22, 1.45, dot(uv * vec2(0.72, 0.88), uv * vec2(0.72, 0.88)));
    fragmentColor *= 0.76 + vignette * 0.24;
    fragmentColor *= 1.34;
    fragmentColor = pow(max(fragmentColor, vec3(0.0)), vec3(0.86));

    return vec4(clamp(fragmentColor, 0.0, 1.0), 1.0) * color;
}
