out vec4 outputColor;
uniform vec3 screenSize; // 1/width, 1/height, aspect ratio
uniform ivec3 ChunkPosition;
uniform mediump sampler3D chunkData;

vec2 getUV() {
    vec2 UV = gl_FragCoord.xy * screenSize.xy; // set fragcoord to screen space
    UV = UV * 2.0 - 1.0; // center the uv
    UV.x *= screenSize.z; // set aspect ratio
    return UV;
}

#define CHUNKWIDTH 8
#define LAYERSIZE (CHUNKWIDTH * CHUNKWIDTH)
#define CHUNKSIZE (LAYERSIZE * CHUNKWIDTH)

vec3 traceRay(vec2 UV) {
    vec3 dir = rotateVector(normalize(vec3(UV, 1.0)), cameraRot);
    Ray ray = createRay(cameraPos, dir);

    vec3 color = vec3(0.0);

    for (int i = 0; i < 1000; i++) { // limit the ray to 20 steps
        // Convert ray position to chunk-local coordinates
        vec3 chunkLocalPos = ray.position - vec3(ChunkPosition);
        
        ivec3 ipos = ivec3(chunkLocalPos);
        if (ipos.x >= 0 && ipos.x < CHUNKWIDTH && // if the ray is inside the chunk then check collisions
            ipos.y >= 0 && ipos.y < CHUNKWIDTH &&
            ipos.z >= 0 && ipos.z < CHUNKWIDTH) {
            vec4 voxel = texture(chunkData, (chunkLocalPos / float(CHUNKWIDTH)));
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
