// from uqone on shadertoy

float hash(float n) {
	return fract(sin(n)*4378.5453);
}

float pnoise(vec3 o) 
{
	vec3 p = floor(o);

	vec3 fr = fract(o);
	vec3 fr2 = fr * fr;
	vec3 fr3 = fr2 * fr;

	float n = p.x + p.y*57.0 + p.z * 1009.0;

	float a = hash(n+  0.0);
	float b = hash(n+  1.0);
	float c = hash(n+ 57.0);
	float d = hash(n+ 58.0);
	
	float e = hash(n+  0.0 + 1009.0);
	float f = hash(n+  1.0 + 1009.0);
	float g = hash(n+ 57.0 + 1009.0);
	float h = hash(n+ 58.0 + 1009.0);
	
	vec3 t = 3.0 * fr2 - 2.0 * fr3;
	
	float u = t.x;
	float v = t.y;
	float w = t.z;

	// this last bit should be refactored to the same form as the rest :)
	float res1 = a + (b-a)*u +(c-a)*v + (a-b+d-c)*u*v;
	float res2 = e + (f-e)*u +(g-e)*v + (e-f+h-g)*u*v;
	
	float res = res1 * (1.0- w) + res2 * (w);
	
	return res;
}

const mat3 m = mat3( 0.00,  0.80,  0.60,
                    -0.80,  0.36, -0.48,
                    -0.60, -0.48,  0.64 );

float SmoothNoise( vec3 p )
{
    float f;
    f  = 0.5*pnoise( p ); p = m*p*2.02;
    f += 0.25*pnoise( p ); 
	
    return f * (1.0 / (0.5 + 0.25));
}

vec3 getStars(in vec3 dir, int levels, float power) 
{
	vec3 color =vec3(0.0);
	vec3 st = (dir * 2.+ vec3(0.3,2.5,1.25)) * .3;
	for (int i = 0; i < levels; i++) {
        st = abs(st) / dot(st,st) - .9;
    }
    float star = min( 1., pow( min( 5., length(st) ), 3. ) * 0.0025 )*1.5;

   	vec3 randc = vec3(SmoothNoise( dir.xyz*10.0*float(levels) ), SmoothNoise( dir.xzy*10.0*float(levels) ), SmoothNoise( dir.yzx*10.0*float(levels) ));
	color += star * randc;

	return pow(color*2.25, vec3(power));
}

vec3 renderSky(vec3 dir) {
    vec3 color=clamp(getStars(dir, 1, 0.5) * 1.5, 0.0, 1.0) * vec3(0.0, 0.0, 1.0);
	vec3 color2=clamp(getStars(-dir, 2, 0.5) * 0.9, 0.0, 1.0) * vec3(1.0, 0.0, 0.0);
    vec3 color3=clamp(getStars(-dir, 3, 0.5) * 0.7, 0.0, 1.0) * vec3(1.0, 1.0, 0.0);
    
    vec3 colorStars=clamp(getStars(dir, 17, 0.9), 0.0, 1.0);
    color = color + color2 + color3 + colorStars;
	color = clamp(color,vec3(0.0),vec3(1.0));
    color = pow(color, vec3(1.2));
	return color;
}