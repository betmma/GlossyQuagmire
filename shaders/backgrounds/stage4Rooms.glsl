uniform float time;
uniform vec3 translation;
uniform float pitch;
uniform float yaw;
uniform float roll;
uniform float roll_per_room;
uniform float zoom_factor;
uniform float portal_zoom_base;
uniform float front_door_open;
uniform float back_door_open;
uniform vec2 screenCenter;
uniform Image snapshot;

const float ROOM_HALF_WIDTH = 3.2;
const float ROOM_HALF_HEIGHT = 2.2;
const float ROOM_HALF_LENGTH = 4.0;
const float ROOM_WALL_THICKNESS = 0.14;
const float DOOR_THICKNESS = 0.045;
const float HIT_EPSILON = 0.0025;
const float MAX_TRAVEL = 48.0;
const float PROJECTED_CAMERA_FOCAL_LENGTH = 0.675;

// Keep this fixed projected-room value synchronized with the corresponding
// constant in backgrounds/stage4Rooms.lua. They define the camera used when
// the single screenshot is placed onto the replacement room.
const float PROJECTED_CAMERA_Z = -3.9;

vec2 rotatePlane(vec2 point, float angle) {
    float cosine = cos(angle);
    float sine = sin(angle);
    return vec2(
        point.x * cosine - point.y * sine,
        point.x * sine + point.y * cosine
    );
}

float wrapCoordinate(float value, float halfRange) {
    float range = halfRange * 2.0;
    return mod(value + halfRange, range) - halfRange;
}

vec3 rotatePitch(vec3 direction, float angle) {
    float cosine = cos(angle);
    float sine = sin(angle);
    return vec3(
        direction.x,
        direction.y * cosine - direction.z * sine,
        direction.y * sine + direction.z * cosine
    );
}

vec3 rotateYaw(vec3 direction, float angle) {
    float cosine = cos(angle);
    float sine = sin(angle);
    return vec3(
        direction.x * cosine + direction.z * sine,
        direction.y,
        -direction.x * sine + direction.z * cosine
    );
}

vec4 projectedSurfaceSample(vec3 point) {
    vec3 C = vec3(0.0, 0.0, PROJECTED_CAMERA_Z);
    vec3 P = point;
    vec3 Q = P - C;
    if(Q.z <= 0.001) {
        return vec4(0.0);
    }
    float screenScale = love_ScreenSize.y * PROJECTED_CAMERA_FOCAL_LENGTH / Q.z;
    vec2 pixel = screenCenter + Q.xy * screenScale;
    vec2 uv = pixel / love_ScreenSize.xy;
    if(uv.x < 0.0 || uv.x >= 1.0 || uv.y < 0.0 || uv.y >= 1.0) {
        return vec4(0.0);
    }
    return Texel(snapshot, uv);
}

float boxDistance(vec3 point, vec3 halfSize) {
    vec3 offset = abs(point) - halfSize;
    return length(max(offset, vec3(0.0))) + min(max(offset.x, max(offset.y, offset.z)), 0.0);
}

void keepNearer(inout vec2 nearest, float distance, float material) {
    if(distance < nearest.x) {
        nearest = vec2(distance, material);
    }
}

float shojiPanelDistance(vec3 point, float wallZ, float side, float openness) {
    float panelHalfWidth = ROOM_HALF_WIDTH * 0.5;
    float panelCenterX = side * (panelHalfWidth + openness * panelHalfWidth);
    vec3 panelCenter = vec3(panelCenterX, 0.0, wallZ);
    vec3 panelSize = vec3(panelHalfWidth, ROOM_HALF_HEIGHT - 0.13, DOOR_THICKNESS);
    return boxDistance(point - panelCenter, panelSize);
}

void addShojiWall(inout vec2 nearest, vec3 point, float wallZ, float openness) {
    keepNearer(nearest, shojiPanelDistance(point, wallZ, -1.0, openness), 4.0);
    keepNearer(nearest, shojiPanelDistance(point, wallZ, 1.0, openness), 4.0);

    float edgeBeamHalfWidth = 0.09;
    float horizontalBeamHalfHeight = 0.09;
    vec3 leftBeamCenter = vec3(-ROOM_HALF_WIDTH + edgeBeamHalfWidth, 0.0, wallZ);
    vec3 rightBeamCenter = vec3(ROOM_HALF_WIDTH - edgeBeamHalfWidth, 0.0, wallZ);
    vec3 upperBeamCenter = vec3(0.0, ROOM_HALF_HEIGHT - horizontalBeamHalfHeight, wallZ);
    vec3 lowerBeamCenter = vec3(0.0, -ROOM_HALF_HEIGHT + horizontalBeamHalfHeight, wallZ);
    vec3 verticalBeamSize = vec3(edgeBeamHalfWidth, ROOM_HALF_HEIGHT, DOOR_THICKNESS * 1.8);
    vec3 horizontalBeamSize = vec3(ROOM_HALF_WIDTH, horizontalBeamHalfHeight, DOOR_THICKNESS * 1.8);
    keepNearer(nearest, boxDistance(point - leftBeamCenter, verticalBeamSize), 5.0);
    keepNearer(nearest, boxDistance(point - rightBeamCenter, verticalBeamSize), 5.0);
    keepNearer(nearest, boxDistance(point - upperBeamCenter, horizontalBeamSize), 5.0);
    keepNearer(nearest, boxDistance(point - lowerBeamCenter, horizontalBeamSize), 5.0);
}

vec2 roomDistance(vec3 point, float frontOpen, float backOpen) {
    vec3 floorCenter = vec3(0.0, -ROOM_HALF_HEIGHT - ROOM_WALL_THICKNESS * 0.5, 0.0);
    vec3 ceilingCenter = vec3(0.0, ROOM_HALF_HEIGHT + ROOM_WALL_THICKNESS * 0.5, 0.0);
    vec3 floorSize = vec3(ROOM_HALF_WIDTH + ROOM_WALL_THICKNESS, ROOM_WALL_THICKNESS * 0.5, ROOM_HALF_LENGTH + ROOM_WALL_THICKNESS);
    vec3 leftWallCenter = vec3(-ROOM_HALF_WIDTH - ROOM_WALL_THICKNESS * 0.5, 0.0, 0.0);
    vec3 rightWallCenter = vec3(ROOM_HALF_WIDTH + ROOM_WALL_THICKNESS * 0.5, 0.0, 0.0);
    vec3 sideWallSize = vec3(ROOM_WALL_THICKNESS * 0.5, ROOM_HALF_HEIGHT + ROOM_WALL_THICKNESS, ROOM_HALF_LENGTH + ROOM_WALL_THICKNESS);

    vec2 nearest = vec2(boxDistance(point - floorCenter, floorSize), 2.0);
    keepNearer(nearest, boxDistance(point - ceilingCenter, floorSize), 3.0);
    keepNearer(nearest, boxDistance(point - leftWallCenter, sideWallSize), 1.0);
    keepNearer(nearest, boxDistance(point - rightWallCenter, sideWallSize), 1.0);
    addShojiWall(nearest, point, ROOM_HALF_LENGTH, frontOpen);
    addShojiWall(nearest, point, -ROOM_HALF_LENGTH, backOpen);
    return nearest;
}

vec3 roomNormal(vec3 point, float frontOpen, float backOpen) {
    float epsilon = 0.004;
    float xPositive = roomDistance(point + vec3(epsilon, 0.0, 0.0), frontOpen, backOpen).x;
    float xNegative = roomDistance(point - vec3(epsilon, 0.0, 0.0), frontOpen, backOpen).x;
    float yPositive = roomDistance(point + vec3(0.0, epsilon, 0.0), frontOpen, backOpen).x;
    float yNegative = roomDistance(point - vec3(0.0, epsilon, 0.0), frontOpen, backOpen).x;
    float zPositive = roomDistance(point + vec3(0.0, 0.0, epsilon), frontOpen, backOpen).x;
    float zNegative = roomDistance(point - vec3(0.0, 0.0, epsilon), frontOpen, backOpen).x;
    return normalize(vec3(xPositive - xNegative, yPositive - yNegative, zPositive - zNegative));
}

float lineMask(float coordinate, float spacing, float halfWidth) {
    float localCoordinate = abs(mod(coordinate + spacing * 0.5, spacing) - spacing * 0.5);
    return 1.0 - smoothstep(halfWidth, halfWidth + 0.018, localCoordinate);
}

vec3 shojiColor(vec3 point, float frontOpen, float backOpen) {
    float openness = backOpen;
    if(point.z > 0.0) {
        openness = frontOpen;
    }
    float side = -1.0;
    if(point.x >= 0.0) {
        side = 1.0;
    }
    float panelHalfWidth = ROOM_HALF_WIDTH * 0.5;
    float panelCenterX = side * (panelHalfWidth + openness * panelHalfWidth);
    float panelX = point.x - panelCenterX;
    float verticalBar = lineMask(panelX, 0.53, 0.032);
    float horizontalBar = lineMask(point.y, 0.46, 0.026);
    float frame = max(verticalBar, horizontalBar);
    float paperVariation = 0.025 * sin(panelX * 13.0 + point.y * 9.0 + time * 0.03);
    vec3 paper = vec3(0.82, 0.76, 0.61) + vec3(paperVariation);
    vec3 wood = vec3(0.12, 0.065, 0.033);
    return mix(paper, wood, frame);
}

vec4 surfaceColor(vec3 point, vec3 normal, vec3 rayDirection, float material, float travel, float frontOpen, float backOpen, float projectedMode) {
    if(projectedMode > 0.5) {
        vec3 texturePoint = point;
        if(material >= 3.5 && material < 4.5 && point.z > 0.0) {
            float panelSide = point.x < 0.0 ? -1.0 : 1.0;
            texturePoint.x = point.x - panelSide * ROOM_HALF_WIDTH * 0.5 * frontOpen;
        }
        vec4 projectedColor = projectedSurfaceSample(texturePoint);
        if(projectedColor.a > 0.0) {
            return vec4(projectedColor.rgb, 1.0);
        }
    }

    vec3 baseColor = vec3(0.20, 0.16, 0.11);

    if(material < 1.5) {
        float beam = lineMask(point.z, 1.0, 0.055);
        vec3 plaster = vec3(0.42, 0.37, 0.28);
        vec3 wood = vec3(0.10, 0.052, 0.027);
        baseColor = mix(plaster, wood, beam);
    }else if(material < 2.5) {
        float matEdgeX = lineMask(point.x, 1.58, 0.035);
        float matEdgeZ = lineMask(point.z, 2.0, 0.035);
        float matEdge = max(matEdgeX, matEdgeZ);
        vec3 tatami = vec3(0.31, 0.30, 0.16);
        vec3 border = vec3(0.075, 0.065, 0.040);
        baseColor = mix(tatami, border, matEdge);
    }else if(material < 3.5) {
        float ceilingBeam = lineMask(point.z, 1.15, 0.065);
        baseColor = mix(vec3(0.25, 0.20, 0.14), vec3(0.085, 0.045, 0.025), ceilingBeam);
    }else if(material < 4.5) {
        baseColor = shojiColor(point, frontOpen, backOpen);
    }else{
        float grain = 0.5 + 0.5 * sin(point.y * 21.0 + point.x * 5.0);
        baseColor = mix(vec3(0.07, 0.032, 0.016), vec3(0.16, 0.078, 0.034), grain * 0.35);
    }

    vec3 lightDirection = normalize(vec3(-0.35, 0.72, -0.46));
    float diffuse = 0.52 + 0.48 * max(dot(normal, lightDirection), 0.0);
    float facing = 0.72 + 0.28 * abs(dot(normal, -rayDirection));
    vec3 shaded = baseColor * diffuse * facing;

    if(material >= 3.5 && material < 4.5) {
        shaded = shaded + baseColor * 0.22;
    }

    float fog = 1.0 - exp(-travel * 0.045);
    return vec4(mix(shaded, vec3(0.055, 0.045, 0.040), fog * 0.62), 0.0);
}

vec4 rayMarchRoom(vec3 rayOrigin, vec3 rayDirection) {
    vec3 point = rayOrigin;
    float travel = 0.0;
    float activeFrontOpen = front_door_open;
    float activeBackOpen = back_door_open;
    float activeProjected = Texel(snapshot, vec2(0.0)).a;
    float portalCount = 0.0;

    for(int stepIndex=0; stepIndex<96; stepIndex++) {
        vec2 scene = roomDistance(point, activeFrontOpen, activeBackOpen);
        float hitEpsilon = HIT_EPSILON * zoom_factor;
        if(scene.x < hitEpsilon) {
            vec3 normal = roomNormal(point, activeFrontOpen, activeBackOpen);
            return surfaceColor(point, normal, rayDirection, scene.y, travel, activeFrontOpen, activeBackOpen, activeProjected);
        }

        float stepDistance = max(scene.x, hitEpsilon);
        vec3 previousPoint = point;
        point = point + rayDirection * stepDistance;
        travel = travel + stepDistance;

        if(point.z > ROOM_HALF_LENGTH) {
            if(portalCount < 0.5) {
                float intersectionRatio = (ROOM_HALF_LENGTH - previousPoint.z) / (point.z - previousPoint.z);
                point = mix(previousPoint, point, intersectionRatio);
                travel = travel - stepDistance + stepDistance * intersectionRatio;
                point.xy = rotatePlane(point.xy, roll_per_room) * portal_zoom_base;
                point.x = wrapCoordinate(point.x, ROOM_HALF_WIDTH + ROOM_WALL_THICKNESS);
                point.y = wrapCoordinate(point.y, ROOM_HALF_HEIGHT + ROOM_WALL_THICKNESS);
                point.z = -ROOM_HALF_LENGTH;
                if(abs(point.x) > ROOM_HALF_WIDTH) {
                    return surfaceColor(point, vec3(0.0, 0.0, -1.0), rayDirection, 1.0, travel, 0.0, 0.0, activeProjected);
                }
                if(point.y < -ROOM_HALF_HEIGHT) {
                    return surfaceColor(point, vec3(0.0, 0.0, -1.0), rayDirection, 2.0, travel, 0.0, 0.0, activeProjected);
                }
                if(point.y > ROOM_HALF_HEIGHT) {
                    return surfaceColor(point, vec3(0.0, 0.0, -1.0), rayDirection, 3.0, travel, 0.0, 0.0, activeProjected);
                }
                rayDirection.xy = rotatePlane(rayDirection.xy, roll_per_room);
                rayDirection = normalize(rayDirection);
                activeFrontOpen = 0.0;
                activeBackOpen = front_door_open;
                activeProjected = 0.0;
                portalCount = portalCount + 1.0;
            }else{
                break;
            }
        }

        if(travel > MAX_TRAVEL * zoom_factor) {
            break;
        }
    }

    return vec4(0.045, 0.038, 0.035, 0.0);
}

vec4 effect(vec4 color, Image texture, vec2 textureCoords, vec2 screenCoords) {
    vec2 uv = (screenCoords.xy - screenCenter) / love_ScreenSize.xy;
    uv.x = uv.x * (love_ScreenSize.x / love_ScreenSize.y);

    vec3 rayOrigin = translation;
    vec3 rayDirection = normalize(vec3(uv.x, uv.y, PROJECTED_CAMERA_FOCAL_LENGTH));
    rayDirection = rotateYaw(rayDirection, yaw);
    rayDirection = rotatePitch(rayDirection, pitch);
    rayDirection.xy = rotatePlane(rayDirection.xy, roll);
    rayDirection = normalize(rayDirection);

    vec4 marchedColor = rayMarchRoom(rayOrigin, rayDirection);
    vec3 fragmentColor = marchedColor.rgb;
    if(marchedColor.a < 0.5) {
        float vignette = 1.0 - smoothstep(0.10, 0.55, dot(uv, uv));
        fragmentColor = fragmentColor * (0.82 + vignette * 0.18);
        fragmentColor = pow(max(fragmentColor, vec3(0.0)), vec3(0.88));
    }
    return vec4(clamp(fragmentColor, 0.0, 1.0), 1.0) * color;
}
