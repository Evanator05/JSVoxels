#version 300 es
precision highp float; // high floating point precision

out vec4 outputColor;

const int maxIterations = 80;
const float maxDist = 150.0;

uniform vec3 screenSize; // 1/width, 1/height, aspect ratio

struct Ray {
    vec3 position;
    vec3 direction;
    float dist;
    int iterations;
};

Ray march(Ray ray, float dist) {
    return Ray(ray.position+ray.direction*dist, ray.direction, ray.dist+dist, ray.iterations+1);
}

float sdSphere(vec3 ray, vec3 pos, float radius) {
    return distance(ray, pos) - radius;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

void main() {
    vec2 UV = vec2(gl_FragCoord.x, gl_FragCoord.y)*screenSize.xy;
    UV = UV*2.0-1.0;
    UV.x *= screenSize.z; 

    vec3 color = vec3(0.0);

    Ray ray = Ray(vec3(0.0), normalize(vec3(UV, 1.0)), 0.0, 0);

    for (int i=0;i<maxIterations;i++){
        float dist = sdBox(ray.position-vec3(2.0, -2.0, 5.0), vec3(1.0));
        ray = march(ray, dist);

        if (dist < 0.00001) {
            color = vec3(1.0);
            break;
        }
        if (ray.dist > maxDist) {
            break;
        }
    }

    float depth = ray.dist/maxDist;
    float iterations = float(ray.iterations)/float(maxIterations);

    outputColor = vec4(vec3(iterations), 1.0);
}