vec2 getUV() {
    vec2 UV = gl_FragCoord.xy * screenSize.xy; // set fragcoord to screen space
    UV = UV * 2.0 - 1.0; // center the uv
    UV.x *= screenSize.z; // set aspect ratio
    return UV;
}

#define CHUNKWIDTH 8
#define LAYERSIZE (CHUNKWIDTH * CHUNKWIDTH)
#define CHUNKSIZE (LAYERSIZE * CHUNKWIDTH)

bool pointInBox(vec3 point, vec3 size) {
    return (point.x >= 0.0 && point.x < size.x && point.y >= 0.0 && point.y < size.y && point.z >= 0.0 && point.z < size.z);
}

vec3 skybox(vec3 dir) {
    return renderSky(dir).rgb;
}

#define MAX_VOXELS 64

vec3[MAX_VOXELS] DDAVoxels(vec3 rayOrigin, vec3 rayDirection) {
    vec3 point = floor(rayOrigin);
    vec3 steps = sign(rayDirection);
    vec3 delta = 1.0/max(abs(rayDirection), 0.001);
    vec3 tMax = (1.0-fract(rayOrigin*steps))*delta;

    
    vec3[MAX_VOXELS] points;
    for (int i = 0; i < MAX_VOXELS; i++) {
        points[i] = point;
        vec3 select = step(tMax, tMax.yzx) * step(tMax, tMax.zxy);
        tMax += select*delta;
        point += select*steps;
        
    }
    return points;
}

struct Hit {
    vec3 color;
    vec3 normal;
    bool hit;
};

Hit traceRay(vec2 UV) {
    Hit hit = Hit(vec3(0.0), vec3(0.0), false);

    vec3 dir = normalize(vec3(UV, 1.0));
    dir = rotateVector(dir, cameraRot);
    Ray ray = createRay(cameraPos, dir);

    hit.color = skybox(dir); // make the default color the skybox
    
    vec3[MAX_VOXELS] voxels = DDAVoxels(ray.position, ray.direction);
    vec3 lastPos = ray.position; // used for calculating normals
    for (int i = 0; i < MAX_VOXELS; i++) {
        vec3 pos = voxels[i];
        vec3 chunkLocalPos = pos - vec3(ChunkPosition);
        if (pointInBox(chunkLocalPos, vec3(CHUNKWIDTH))) {
            vec4 voxel = texture(chunkData, chunkLocalPos/float(CHUNKWIDTH));
            if (voxel.a == 1.0) {
                hit.color = voxel.rgb;
                hit.normal = sign(lastPos-pos);
                break;
            }
        }
        lastPos = pos;
    }
    return hit;
}

void main() {
    vec2 UV = getUV();
    Hit hit = traceRay(UV);
    outputColor = vec4(hit.color, 1.0);
}
