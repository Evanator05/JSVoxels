out vec4 outputColor;

const int maxIterations = 80;
const float maxDist = 10.0;

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

    vec3 dir = rotateVector(normalize(vec3(UV, 1.0)), cameraRot);

    Ray ray = Ray(cameraPos, dir, 0.0, 0);

    for (int i=0;i<maxIterations;i++){
        float dist = sdBox(ray.position-vec3(2.0, -2.0, 5.0), vec3(1.0));
        
        if (dist < 0.00001) {
            color = vec3(1.0);
            break;
        }

        ray = march(ray, dist);
        
        if (ray.dist > maxDist) {
            break;
        }
    }

    float depth = ray.dist/maxDist;
    float iterations = float(ray.iterations)/float(maxIterations);

    outputColor = vec4(vec3(iterations), 1.0);
}