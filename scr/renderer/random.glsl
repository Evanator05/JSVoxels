float random(vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

vec2 randomVec2(vec2 st) {
    return vec2(random(st), random(st+1.0));
}

vec3 randomVec3(vec2 st) {
    return vec3(randomVec2(st), random(st+2.0));
}

vec4 randomVec4(vec2 st) {
    return vec4(randomVec3(st), random(st+3.0));
}

vec3 randomColor(vec2 st) {
    return randomVec3(st);
}