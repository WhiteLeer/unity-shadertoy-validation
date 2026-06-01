#define SPEED 15.0
#define FREQ 8.
#define MAX_HEIGHT 0.3
#define THICKNESS 0.005
#define BLOOM 0.65 // above 1 will reduce
#define WOBBLE 0.1 // how much each end wobbles

float beam(vec2 uv, float max_height, float offset, float speed, float freq, float thickness) {
	uv.y -= 0.5;

	float height = max_height * (WOBBLE + min(1. - uv.x, 1.));

	// Ramp makes the left hand side stay at/near 0
	float ramp = smoothstep(0., 2.0 / freq, uv.x);

    height *= ramp;
	uv.y += sin(uv.x * freq - iTime * speed + offset) * height;

	float f = thickness / abs(uv.y);
	f = pow(f, BLOOM);
	
	return f;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    
    float f = beam(uv, MAX_HEIGHT, 0., SPEED, FREQ * 1.5, THICKNESS * 0.5) + 
			  beam(uv, MAX_HEIGHT, iTime, SPEED, FREQ, THICKNESS) +
			  beam(uv, MAX_HEIGHT, iTime + 0.5, SPEED + 0.2, FREQ * 0.9, THICKNESS * 0.5) + 
			  beam(uv, 0., 0., SPEED, FREQ, THICKNESS * 3.0);
    
    fragColor = vec4(f * vec3(0.5, 0.05, 0.15), 1.0);
}
