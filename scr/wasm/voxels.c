#define MAX_RED 3;
#define MAX_GREEN 3;
#define MAX_BLUE 2;

typedef unsigned char voxel;
typedef unsigned char uint_8;

typedef struct Chunk {
    uint_8 x, y, z;    
    voxel voxels[8][8][8];
} chunk;


voxel x = 0b11111111;