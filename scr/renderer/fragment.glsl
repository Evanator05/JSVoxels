out vec4 outputColor;
uniform vec3 screenSize; // 1/width, 1/height, aspect ratio
uniform ivec3 ChunkPosition;
uniform lowp sampler3D chunkData;

bool showBoundingBox = false;

vec2 getUV() {
    vec2 UV = gl_FragCoord.xy * screenSize.xy; // set fragcoord to screen space
    UV = UV * 2.0 - 1.0; // center the uv
    UV.x *= screenSize.z; // set aspect ratio
    return UV;
}

#define CHUNKWIDTH 8
#define INVERSECHUNKWIDTH 1.0/float(CHUNKWIDTH)
#define LAYERSIZE (CHUNKWIDTH * CHUNKWIDTH)
#define CHUNKSIZE (LAYERSIZE * CHUNKWIDTH)
#define RAYDIST 32

bool pointInBox(vec3 point, vec3 size) {
    return (point.x >= 0.0 && point.x < size.x && point.y >= 0.0 && point.y < size.y && point.z >= 0.0 && point.z < size.z);
}

vec3 skybox(vec3 dir) {
    return dir;
}

#define MAX_VOXELS 32

vec3[MAX_VOXELS] DDAVoxels(vec3 rayOrigin, vec3 rayDirection) {
    
    vec3 steps = sign(rayDirection);
    vec3 delta = 1.0/max(abs(rayDirection), 0.001);
    vec3 tMax = (1.0-fract(rayOrigin*steps))*delta;

    vec3 point = floor(rayOrigin);
    vec3[MAX_VOXELS] points;
    for (int i = 0; i < MAX_VOXELS; i++) {
        points[i] = point;

        bvec3 a = lessThan(tMax, tMax.yzx);
        bvec3 b = lessThanEqual(tMax, tMax.zxy);
        vec3 select = vec3(a)*vec3(b);

        point += select*steps;
        tMax += select*delta;
    }
    return points;
}


vec3 traceRay(vec2 UV) {
    vec3 dir = normalize(vec3(UV, 1.0));
    dir = rotateVector(dir, cameraRot);
    Ray ray = createRay(cameraPos, dir);

    vec3 color = skybox(dir); // make the default color the skybox
    
    vec3[MAX_VOXELS] voxels = DDAVoxels(ray.position, ray.direction);
    for (int i = 0; i < MAX_VOXELS; i++) {
        vec3 pos = voxels[i];
        vec3 chunkLocalPos = round(pos) - vec3(ChunkPosition);
        if (pointInBox(chunkLocalPos, vec3(CHUNKWIDTH))) {
            if (showBoundingBox) { 
                color = vec3(0.0);
            }
            vec4 voxel = texture(chunkData, chunkLocalPos/8.0);
            if (voxel.a == 1.0) {
                color = voxel.rgb;
                break;
            }
        
        }
    }
    return color;
}

void main() {
    vec2 UV = getUV();
    vec3 color = traceRay(UV);
    outputColor = vec4(color, 1.0);
}
