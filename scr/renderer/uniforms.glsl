out vec4 outputColor;
uniform vec3 screenSize; // 1/width, 1/height, aspect ratio
uniform vec2 cameraRot;
uniform vec3 cameraPos;
uniform ivec3 ChunkPosition;
uniform lowp sampler3D chunkData;
uniform float time;
uniform int renderMode; // color normal steps hit