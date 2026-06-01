// Constants (adjust these values as needed)
#define MODE 0  // 0: Left-to-right, 1: Top-to-bottom, 2: Radial
#define LAYERS 5.0
#define SPEED 1.0
#define DELAY 0.0
#define WIDTH 0.05

#define W WIDTH
#define MAX_LAYERS 32.0 // Define a maximum number of layers

vec4 readTex(vec2 uv) {
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        return vec4(0.0);
    }
    return texture(iChannel0, uv);
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(4859.0, 3985.0))) * 3984.0);
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float sdBox(vec2 p, float r) {
    vec2 q = abs(p) - r;
    return min(length(q), max(q.y, q.x));
}

float dir = 1.0;

float toRangeT(vec2 p, float scale) {
    float d;
    
    if (MODE == 0) {
        d = p.x / (scale * 2.0) + 0.5;
    }
    else if (MODE == 1) {
        d = 1.0 - (p.y / (scale * 2.0) + 0.5);
    }
    else if (MODE == 2) {
        d = length(p) / scale;
    }
    
    d = dir > 0.0 ? d : (1.0 - d);
    
    return d;
}

vec4 cell(vec2 p, vec2 pi, float scale, float t, float edge) {
    vec2 pc = pi + 0.5;
    vec2 uvc = pc / scale;
    uvc.y /= iResolution.y / iResolution.x;
    uvc = uvc * 0.5 + 0.5;
    if (uvc.x < 0.0 || uvc.x > 1.0 || uvc.y < 0.0 || uvc.y > 1.0) {
        return vec4(0.0);
    }
    float alpha = smoothstep(0.0, 0.1, texture(iChannel0, uvc).a);
    
    vec4 color = vec4(hsv2rgb(vec3((pc.x * 13.0 / pc.y * 17.0) * 0.3, 1.0, 1.0)), 1.0);
    
    float x = toRangeT(pi, scale);
    float n = hash(pi);
    float anim = smoothstep(W * 2.0, 0.0, abs(x + n * W - t));
    color *= anim;    
    
    color *= mix(
        1.0, 
        clamp(0.3 / abs(sdBox(p - pc, 0.5)), 0.0, 10.0),
        edge * pow(anim, 10.0)
    ); 
    
    return color * alpha;
}

vec4 cellsColor(vec2 p, float scale, float t) {
    vec2 pi = floor(p);
    
    vec2 d = vec2(0.0, 1.0);
    vec4 cc = vec4(0.0);
    cc += cell(p, pi, scale, t, 0.2) * 4.0;
    cc += cell(p, pi + d.xy, scale, t, 0.9);
    cc += cell(p, pi - d.xy, scale, t, 0.9);
    cc += cell(p, pi + d.yx, scale, t, 0.9);
    cc += cell(p, pi - d.yx, scale, t, 0.9);
    
    return cc / 8.0;
}

vec4 draw(vec2 uv, vec2 p, float t, float scale) {
    vec4 c = readTex(uv);
    vec2 pi = floor(p * scale);
    float n = hash(pi);
    t = t * (1.0 + W * 4.0) - W * 2.0;
    
    float x = toRangeT(pi, scale);
    float a1 = smoothstep(t, t - W, x + n * W);    
    c *= a1;
    c += cellsColor(p * scale, scale, t) * 1.5;
    
    return c;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec2 p = uv * 2.0 - 1.0;
    p.y *= iResolution.y / iResolution.x;
    
    // Calculate transition time based on iTime
    float transitionDuration = 2.0; // Adjust this value to change transition duration
    float t = mod(iTime / transitionDuration, 2.0);
    if (t > 1.0) {
        t = 2.0 - t;
        dir = -1.0;
    } else {
        dir = 1.0;
    }
    t = clamp((t - DELAY) * SPEED, 0.0, 1.0);
    t = (fract(t * 0.99999) - 0.5) * dir + 0.5;
    
    vec4 finalColor = vec4(0.0);
    float layerCount = 0.0;
    for (float i = 0.0; i < MAX_LAYERS; i++) {
        if (i >= LAYERS) break;
        float s = cos(i) * 7.3 + 10.0; 
        finalColor += draw(uv, p, t, abs(s));
        layerCount += 1.0;
    }
    fragColor = finalColor / layerCount;  
    
    fragColor *= smoothstep(0.0, 0.01, t);
}
