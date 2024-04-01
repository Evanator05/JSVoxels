#version 300 es
precision highp float; // high floating point precision

out vec4 outputColor;

const int maxIterations = 80;
const int maxDist = 10;

uniform vec3 screenSize; // 1/width, 1/height, aspect ratio

struct Ray {
    vec3 position;
    vec3 direction;
    float dist;
};

Ray march(Ray ray, float dist) {
    return Ray(ray.position+ray.direction*dist, ray.direction, ray.dist+dist);
}

float sdSphere(vec3 ray, vec3 pos, float radius) {
    return distance(ray, pos) - radius;
}

void main() {
    float aspect = screenSize.x/screenSize.y;
    vec2 UV = vec2(gl_FragCoord.x, gl_FragCoord.y)*screenSize.xy;
    UV = UV*2.0-1.0;
    UV.x *= screenSize.z; 

    vec3 color = vec3(0.0);

    Ray ray = Ray(vec3(0.0), normalize(vec3(UV, 1.0)), 0.0);

    for (int i=0;i<maxIterations;i++){
        float dist = sdSphere(ray.position, vec3(0.0, 0.0, 5.0), 1.0);
        if (dist < 0.001) {
            color = vec3(1.0);
            break;
        }
        ray = march(ray, dist);
    }
    
    outputColor = vec4(color, 1.0);
}