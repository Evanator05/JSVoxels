struct Ray {
    vec3 position;
    vec3 direction;
    float dist;
    int iterations;
    bool hit;
};

Ray createRay(vec3 position, vec3 direction) {
    return Ray(position, direction, 0.0, 0, false);
}

Ray march(Ray ray, float dist) {
    return Ray(ray.position+ray.direction*dist, ray.direction, ray.dist+dist, ray.iterations+1, ray.hit);
}
