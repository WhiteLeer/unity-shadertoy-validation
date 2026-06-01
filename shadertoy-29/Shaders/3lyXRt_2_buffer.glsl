// define DEPTH_BUFFER | Z_BUFFER | NORMAL_BUFFER | BASIC_SHADING 
#define Z_BUFFER

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    
    vec3 eye = EYE_POS + vec3(3.0 * cos(iTime), 1.0 * sin(iTime), 0.0);
      
    // Pixel coordinates mapped to [-aspectRatio, aspectRatio] x [-1, 1]
    vec2 uv = 2.0 * fragCoord / iResolution.y - vec2(iResolution.x / iResolution.y, 1.0);

    Ray ray = Ray(eye, normalize(vec3(uv.x * CAMERA.X + uv.y * CAMERA.Y + NEAR_DISTANCE * CAMERA.Z)));

    ISObj nearestObj = ISObj(FAR_DISTANCE, -1, -1);
    
    for (int i = 0; i < PLANE_COUNT; i++) {
   		ISObj raycast = intersectPlane(planes[i], ray, i);
        if(raycast.dist < nearestObj.dist) {
            nearestObj = raycast;
        }
    }
    
    for (int i = 0; i < SPHERE_COUNT; i++) {
   		ISObj raycast = intersectSphere(spheres[i], ray, i);
        if(raycast.dist < nearestObj.dist) {
            nearestObj = raycast;
        }
    }
    
    #ifdef DEPTH_BUFFER
        fragColor = vec4(nearestObj.dist, nearestObj.dist, nearestObj.dist, FAR_DISTANCE) / FAR_DISTANCE;
    #endif
    
    #ifdef Z_BUFFER
    	float z = dot(ray.dir * nearestObj.dist, CAMERA.Z);
        fragColor = vec4(z, z, z, FAR_DISTANCE) / FAR_DISTANCE;
    #endif
    
    #if defined(NORMAL_BUFFER) || defined(BASIC_SHADING)
        vec3 normal;
        if (nearestObj.type == OBJECT_TYPE_PLANE) {
            normal = planes[nearestObj.id].normal;
        } else if (nearestObj.type == OBJECT_TYPE_SPHERE) {
            normal = computeSphereNormal(spheres[nearestObj.id], ray, nearestObj.dist);
        } else {
            normal = vec3(0.0, 0.0, 0.0);
        }

        #ifdef NORMAL_BUFFER
        	fragColor = vec4(normal, 1.0);
        #endif
    
        #ifdef BASIC_SHADING
    		vec4 color;
            if (nearestObj.type == OBJECT_TYPE_PLANE) {
                color = vec4(planes[nearestObj.id].col, 1.0);
            } else if (nearestObj.type == OBJECT_TYPE_SPHERE) {
                color = vec4(spheres[nearestObj.id].col, 1.0);
            } else {
                fragColor = DEFAULT_COLOR;
                return;
            }
        	fragColor = (.5 + -.5 * dot(normal, LIGHT_DIRECTION)) * color;
        #endif
    
    #endif

}
