uniform vec2 cameraRot;
uniform vec3 cameraPos;

vec3 rotateVector(vec3 v, vec2 a) {
	float pitchRad = radians(a.y);
	float yawRad = radians(a.x);
	
	mat3 pitchMatrix = mat3(
		vec3(1.0, 0.0, 0.0),
		vec3(0.0, cos(pitchRad), -sin(pitchRad)),
		vec3(0.0, sin(pitchRad), cos(pitchRad))
	);
	
	mat3 yawMatrix = mat3(
		vec3(cos(yawRad), 0.0, sin(yawRad)),
		vec3(0.0, 1.0, 0.0),
		vec3(-sin(yawRad), 0.0, cos(yawRad))
    );
	
	return yawMatrix*pitchMatrix*v;
}