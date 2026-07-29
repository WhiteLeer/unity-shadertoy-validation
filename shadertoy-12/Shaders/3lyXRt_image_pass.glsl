// ===== PARAMS =====

// Define the raymarch algorithm
// Screen space still have an issue with depth length
// MARCH_SCREEN_SPACE | MARCH_WORLD_SPACE
#define MARCH_WORLD_SPACE

const float _MaxDistance = 15.0;
const float _Step = 0.05;
const float _Thickness = 0.0006;

float map(float value, float min1, float max1, float min2, float max2) {
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 col = texture(iChannel2, uv);
    
    // Fragment shader, this part is used to get the pixels of the ground
    // Get the ground in our case
    if(col == (.5 + -.5 * dot(vec3(0.0, 1.0, 0.0), LIGHT_DIRECTION)) * vec4(.1, .1, .1, 1.0)) {
        
        // SSR Goes there
        
        // We sample the Depth (Buffer A), the normal (Buffer B)
       	// And gather the view ray intersection
        
        // ===== VIEW RAY =====
        vec3 eye = EYE_POS + vec3(3.0 * cos(iTime), 1.0 * sin(iTime), 0.0);
      	// Pixel coordinates mapped to [-aspectRatio, aspectRatio] x [-1, 1]
    	vec2 r_uv = 2.0 * fragCoord / iResolution.y - vec2(iResolution.x / iResolution.y, 1.0);
        vec3 r_dir = vec3(r_uv.x * CAMERA.X + r_uv.y * CAMERA.Y + NEAR_DISTANCE * CAMERA.Z);
		Ray ray = Ray(eye, normalize(r_dir));
        // ====================
        
        float aspect = iResolution.x / iResolution.y;
        
        float depth = texture(iChannel0, uv).x;
        vec3 normal = texture(iChannel1, uv).xyz;
        
        
        vec3 view      = ray.dir * length(r_dir) * depth * FAR_DISTANCE / NEAR_DISTANCE;
        vec3 position  = ray.origin + view;
        vec3 reflected = reflect(normalize(view), normal);
              
        
        vec2 reflectionUV = uv;
        float atten = 0.0f;
        
        #ifdef MARCH_SCREEN_SPACE
 
            // ===== Project onto screen space =====
            // We generated everything with raytracing, but in realtime apps, just use 
            // The camera projection-view matrix here (_ProjectionView * position)
            // Instead, i'll compute the projection by hand
            vec2 screenStart = projectOnScreen(eye, position);
            vec2 screenEnd   = projectOnScreen(eye, position + reflected);
            vec2 screenDir   = (screenEnd - screenStart).xy;
        
            // ===== Ray march in screen space =====
            float reflectedDepth = dot(reflected, CAMERA.Z) / FAR_DISTANCE;
            float depthStep = reflectedDepth;

            float currentDepth = depth;
            vec2 march = screenStart;

            for(float i = 0.0; i < _MaxDistance; i += _Step) {
                march += screenDir * _Step;
                vec2 marchUV;
                marchUV.x = map(march.x, -aspect, aspect, 0.0, 1.0); 
                marchUV.y = map(march.y, -1.0, 1.0, 0.0, 1.0); 
                float targetDepth = texture(iChannel0, marchUV).x;
                float depthDiff = currentDepth - targetDepth;
                if(depthDiff > 0.0 && depthDiff < depthStep) {
                    reflectionUV = marchUV;
                    atten = 1.0 - i / _MaxDistance;
                    break;
                }
                currentDepth += depthStep * _Step;
            }
       	
        #endif
        #ifdef MARCH_WORLD_SPACE
        
            vec3 marchReflection;
            float currentDepth = depth;
            for(float i = _Step; i < _MaxDistance; i+= _Step) {
                marchReflection = i * reflected;
				float targetDepth = dot(view + marchReflection, CAMERA.Z) / FAR_DISTANCE;
                vec2 target = projectOnScreen(eye, position + marchReflection);
                target.x = map(target.x, -aspect, aspect, 0.0, 1.0); 
                target.y = map(target.y, -1.0, 1.0, 0.0, 1.0); 
                float sampledDepth = texture(iChannel0, target).x;
                float depthDiff = sampledDepth - currentDepth;
                if(depthDiff > 0.0 && depthDiff < targetDepth - currentDepth + _Thickness) {
                    reflectionUV = target;
                    atten = 1.0 - i / _MaxDistance;
                    break;
                }
                currentDepth = targetDepth;
                if(currentDepth > 1.0) {
                    atten = 1.0;
                    break;
                }
            }
        
        #endif

        fragColor = vec4(reflectionUV - uv, 0., 1.);
    	fragColor = vec4(texture(iChannel2, reflectionUV).rgb * atten + col.rgb, 1.0); 
    } else {
    	fragColor = vec4(col.rgb, 1.);
    }
    
    //fragColor = texture(iChannel0, uv);
    
    fragColor.rgb = pow(fragColor.rgb, vec3(1.0/1.6));

}
