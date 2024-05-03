out vec4 outputColor;
uniform vec3 screenSize; // 1/width, 1/height, aspect ratio
uniform ivec3 ChunkPosition;
uniform lowp sampler3D chunkData;

bool showBoundingBox = true;

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

bool pointInBox(vec3 point, vec3 size) {
    return (point.x >= 0.0 && point.x < size.x && point.y >= 0.0 && point.y < size.y && point.z >= 0.0 && point.z < size.z);
}

vec3 skybox(vec3 dir) {
    return dir;
}

vec3 traceRay(vec2 UV) {
    vec3 dir = rotateVector(normalize(vec3(UV, 1.0)), cameraRot);
    Ray ray = createRay(cameraPos, dir);
    vec3 color = skybox(dir); // make the default color the skybox
    
    for (int i = 0; i < 1000; i++) { // limit the ray steps
        // Convert ray position to chunk-local coordinates
        vec3 chunkLocalPos = floor(ray.position) - vec3(ChunkPosition);
        if (pointInBox(chunkLocalPos, vec3(CHUNKWIDTH))) {
            if (showBoundingBox) { 
                color = vec3(0.0);
            }
            vec4 voxel = texture(chunkData, chunkLocalPos*INVERSECHUNKWIDTH);
            bool solid = voxel.a == 1.0;
            if (solid) {
                ray.hit = true;
                color = voxel.rgb;
                break;
            }
        }
        // move ray
        ray = march(ray, 0.025);
    }
    return color;
}

void main() {
    vec2 UV = getUV();
    vec3 color = traceRay(UV);
    outputColor = vec4(color, 1.0);
}
