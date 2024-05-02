out vec4 outputColor;
uniform vec3 screenSize; // 1/width, 1/height, aspect ratio

vec2 getUV() {
    vec2 UV = gl_FragCoord.xy*screenSize.xy; // set fragcoord to screen space
    UV = UV*2.0-1.0; // center the uv
    UV.x *= screenSize.z; // set aspect ratio
    return UV;
}

const int maxIterations = 80;
const float maxDist = 10.0;

struct Voxel {
    bool solid;
    vec3 color;
};

#define CHUNKWIDTH 8
#define LAYERSIZE CHUNKWIDTH*CHUNKWIDTH
#define CHUNKSIZE LAYERSIZE*CHUNKWIDTH
struct Chunk {
    ivec3 position;
    Voxel[CHUNKSIZE] voxels;
};

int posToChunkIndex(vec3 pos) {
    ivec3 ipos = ivec3(floor(pos));
    return (ipos.z*LAYERSIZE)+(ipos.y*CHUNKWIDTH)+(ipos.x);
}

Chunk generateRandomChunk() {
    Voxel[CHUNKSIZE] voxels; 
    for (int i = 0; i < CHUNKSIZE; i++) {
        voxels[i] = Voxel(bool(round(random(vec2(i)))), randomColor(vec2(i)));
    }

    return Chunk(ivec3(0), voxels);
}

vec3 traceRay(vec2 UV, Chunk chunk) {
    vec3 dir = rotateVector(normalize(vec3(UV, 1.0)), cameraRot);
    Ray ray = createRay(cameraPos, dir);

    vec3 color = vec3(0.0);

    int count = 0;

    while (count < maxIterations) {
        Voxel voxel = chunk.voxels[posToChunkIndex(ray.position)];
        if (voxel.solid) {
            ray.hit = true;
            color = voxel.color;
            break;
        }
        
        ray = march(ray, 0.2);
        count++;
    }

    //Voxel voxel = chunk.voxels[posToChunkIndex(ray.position)];
    return color;
}

void main() {
    
    vec2 UV = getUV();

    Chunk chunk = generateRandomChunk();

    vec3 ray = traceRay(UV, chunk);

    outputColor = vec4(ray, 1.0);
}