/**
 * -----------------------------------------------------------
 * -- Scene Shading
 * -----------------------------------------------------------
 *
 * Applies basic lighting and subsurface scattering to the scene.
 * No additional effects (such as shadows or ambient occlusion) are
 * applied as to not detract from the focus on SSS.
 */

float SSSAmbient     = 1.0;
float SSSDistortion  = 1.0;
float SSSPower       = 1.0;
float SSSScale       = 1.0;
vec3  LightCol       = vec3(1.0);
vec3  LightPos       = vec3(0.0);

//------------------------------------------------------------------------------------------
// Utilities
//------------------------------------------------------------------------------------------

float UISlider(int id)
{
    return texture(iChannel1, vec2(float(id) + 0.5, 0.5) / iResolution.xy).r;
}

vec3 UIColor(int id)
{
    return texture(iChannel1, vec2(float(id) + 0.5, 1.5) / iResolution.xy).rgb;
}

void UpdateParameters()
{
    SSSAmbient     = max(0.01, UISlider(3));
    SSSDistortion  = max(0.01, UISlider(4)) * 2.0;
    SSSPower       = max(0.01, UISlider(5)) * 2.0;
    SSSScale       = max(0.01, UISlider(6)) * 5.0;
    LightCol       = UIColor(7);
}

// Octrahedron normals unpacking (https://www.shadertoy.com/view/Mtfyzl)
vec3 UnpackNormal(uint data, uint sh)
{
    uint mu =(1u<<sh)-1u;
    
    uvec2 d = uvec2( data, data>>sh ) & mu;
    vec2 v = vec2(d)/float(mu);
    
    v = -1.0 + 2.0*v;
    vec3 nor;
    nor.z = 1.0 - abs(v.x) - abs(v.y);
    nor.xy = (nor.z>=0.0) ? v.xy : (1.0-abs(v.yx))*sign(v.xy);
    return normalize( nor );
}

//------------------------------------------------------------------------------------------
// Ray / Camera
//------------------------------------------------------------------------------------------

struct Ray
{
	vec3 o;
    vec3 d;
};

Ray Ray_LookAt(in vec2 uv, in vec3 o, in vec3 d)
{
    vec3 forward = normalize(d - o);
    vec3 right   = normalize(cross(forward, vec3(0.0, 1.0, 0.0)));
    vec3 up      = normalize(cross(right, forward));

    uv    = (uv * 2.0) - 1.0;
    uv.x *= (iResolution.x / iResolution.y);

    Ray ray;
    ray.o = o;
    ray.d = normalize((uv.x * right) + (uv.y * up) + (forward * 2.0));

    return ray;
}

vec3 OrbitAround(vec3 origin, float radius, float rate)
{
  	return vec3((origin.x + (radius * cos(iTime * rate))), (origin.y), (origin.z + (radius * sin(iTime * rate))));
}

vec3 CameraPos()
{
	return OrbitAround(vec3(0.0), 6.5, 0.25);
}

//------------------------------------------------------------------------------------------
// Render
//------------------------------------------------------------------------------------------

float Attenuation(in vec3 toLight)
{
    float d = length(toLight);
    return 1.0 / (1.0 + 1.0 * d + 1.0 * d * d);
}

vec3 Render(
    in Ray   ray,
    in vec3  norm, 
    in float depth, 
    in float surfID,
    in float thickness)
{
    vec3 color = vec3(0.047);
    
    if(depth < 1.0)
    {
        if(surfID > 1.5)
        {
            // The light sphere, don't perform any actual shading on it.
			return LightCol + 0.9;
        }
        
        float sssEnabled = UISlider(0);
        
        vec3  position    = ray.o + (ray.d * depth * 10.0);
        vec3  toLight     = LightPos - position;
        vec3  albedo      = vec3(1.0);
        vec3  diffuse     = LightCol;
        float attenuation = Attenuation(toLight);
        
        if(sssEnabled < 0.5)
        {
            // SSS disabled, do extremely basic direct point lighting
            color = albedo * attenuation * diffuse * max(0.0, dot(norm, normalize(toLight)));
        }
        else
        {
            // SSS enabled
            vec3  toEye    = -ray.d;
			vec3  SSSLight = (normalize(LightPos - position) + norm * SSSDistortion);
        	float SSSDot   = pow(clamp(dot(toEye, -SSSLight), 0.0, 1.0), SSSPower) * SSSScale;
        	float SSS      = (SSSDot + SSSAmbient) * thickness * attenuation;
            
            color = albedo * diffuse * SSS;
        }
    }
    
    return color;
}

//------------------------------------------------------------------------------------------
// Main
//------------------------------------------------------------------------------------------

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    UpdateParameters();
    
    vec2 uv = (fragCoord / iResolution.xy);
    vec4 tx = texelFetch(iChannel0, ivec2(fragCoord), 0);
    
    LightPos.y = sin(iTime) * 3.0;
    
    Ray   ray       = Ray_LookAt(uv, CameraPos(), vec3(0.0, -0.25, 0.0));
    vec3  normal    = UnpackNormal(uint(tx.a), 14u);
    float depth     = tx.r;
    float thickness = tx.g;
    float surfID    = tx.b;
    
    fragColor = vec4(Render(ray, normal, depth, surfID, thickness), 1.0);
}

