// Similar shaders I referenced:
// https://www.shadertoy.com/view/MtVGWV
// https://www.shadertoy.com/view/lsscWr

#define NUM_OCTAVES 4
#define NUM_STEPS 4.0
#define FLAME_SIZE 5.7
//#define ALLOW_MOUSE_INPUT

// 2D Noise from IQ
float Noise2D( in vec2 x ) {
    ivec2 p = ivec2(floor(x));
    vec2 f = fract(x);
	f = f*f*(3.0-2.0*f);
	ivec2 uv = p.xy;
	float rgA = texelFetch( iChannel0, (uv+ivec2(0,0))&255, 0 ).x;
    float rgB = texelFetch( iChannel0, (uv+ivec2(1,0))&255, 0 ).x;
    float rgC = texelFetch( iChannel0, (uv+ivec2(0,1))&255, 0 ).x;
    float rgD = texelFetch( iChannel0, (uv+ivec2(1,1))&255, 0 ).x;
    return mix( mix( rgA, rgB, f.x ),
                mix( rgC, rgD, f.x ), f.y );
}

float ComputeFBM( in vec2 pos ) {
    float amplitude = 1.0;
    float sum = 0.0;
    float maxAmp = 0.0;
    for(int i = 0; i < NUM_OCTAVES; ++i) {
        sum += Noise2D(pos) * amplitude;
        maxAmp += amplitude;
        amplitude *= 0.5;
        pos *= 2.0;
    }
    return sum / maxAmp; // normalize to [0, 1]
}

// Fiery palette taken from https://www.shadertoy.com/view/4tlSzl
// Not currently used in this shader
vec3 firePalette( float i ) {
    float T = 1400.0 + 1300.0 * i; // Temperature range (in Kelvin).
    vec3 L = vec3(7.4, 5.6, 4.4); // Red, green, blue wavelengths (in hundreds of nanometers).
    L = pow(L, vec3(5.0)) * (exp(1.43876719683e5 / (T * L)) - 1.0);
    return 1.0 - exp(-5e8/L); // Exposure level. Set to "50." For "70," change the "5" to a "7," etc.
}

// Courtesy of Shane
vec3 firePaletteCheap( float i ) {
	return pow(vec3(1.65, 1.2, 1.0) * i, vec3(1.0, 2.5, 12.0));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    // Normalized device coordinates
    vec2 ndc = (2.0 * fragCoord.xy - iResolution.xy) / iResolution.y;
    float uvy = (ndc.y + 1.0) / 2.0;
    
    float noise = ComputeFBM(ndc * vec2(2.0, 1) * 3.5 + vec2(0.0, -iTime * 7.0));
    
    // Offset version of first noise (offset values chosen pretty arbitrarily)
    float noise2 = ComputeFBM(ndc + vec2(-iTime * sin(iTime * 0.005) * 0.3 - 50.0, 121.0));
    
    // Attenuate noise w/ noise
    noise *= pow(noise2, 0.55);
    
    // Hand modeling the noise... lots of magic numbers
    vec2 mouseEffect = vec2(1.4, 0.85); // ok default parameters
    #ifdef ALLOW_MOUSE_INPUT
    mouseEffect = vec2(1.0) - iMouse.xy / iResolution.xy; mouseEffect *= 2.0;
    #endif
    noise *= (FLAME_SIZE - pow(uvy * 21.0 * mouseEffect.y + abs(ndc.x) * 14.0, 0.57) * mouseEffect.x);
    
    // Debug view of falloff
    //fragColor = vec4(vec3(noise), 1); return;
    
    noise = clamp(noise, 0.0, 1.0);
    noise = floor(noise * NUM_STEPS) / NUM_STEPS;
    //noise = floor(noise * NUM_STEPS * .999) / (NUM_STEPS - 1.0);
    vec3 fireColor = firePaletteCheap(noise);
    fragColor = vec4(fireColor, 1.0);
}
