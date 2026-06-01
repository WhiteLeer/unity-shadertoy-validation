/**
 * -----------------------------------------------------------
 * -- Scene Marching
 * -----------------------------------------------------------
 *
 * Marches the scene and generates a G-Buffer stored as:
 *
 *    .r = Depth
 *    .g = Thickness
 *    .b = Surface ID
 *    .a = Packed Normal
 */

#define Epsilon  0.001
#define NearClip Epsilon
#define FarClip  10.0
#define MaxSteps 100
#define PI       3.14159265359

float SSSSampleDepth       = 1.0;
float SSSThicknessSamples  = 32.0;
float SSSThicknessSamplesI = 0.03125;

//------------------------------------------------------------------------------------------
// Utilities
//------------------------------------------------------------------------------------------

float UISlider(int id)
{
    return texture(iChannel0, vec2(float(id) + 0.5, 0.5) / iResolution.xy).r;
}

void UpdateParameters()
{
    SSSThicknessSamples  = max(1.0, 64.0 * UISlider(1));
    SSSThicknessSamplesI = 1.0 / SSSThicknessSamples;
	SSSSampleDepth       = max(0.1, 2.0 * UISlider(2));
}

// Octrahedron normals packing (https://www.shadertoy.com/view/Mtfyzl)
uint PackNormal(in vec3 nor, uint sh)
{
    nor /= ( abs( nor.x ) + abs( nor.y ) + abs( nor.z ) );
    nor.xy = (nor.z >= 0.0) ? nor.xy : (1.0-abs(nor.yx))*sign(nor.xy);
    vec2 v = 0.5 + 0.5*nor.xy;

    uint mu = (1u<<sh)-1u;
    uvec2 d = uvec2(floor(v*float(mu)+0.5));
    return (d.y<<sh)|d.x;
}

// Great tip from iq, see: https://www.shadertoy.com/view/4dBXz3
vec3 MirrorVector(in vec3 v, in vec3 n)
{
    return v + 2.0 * n * max(0.0, -dot(n,v));
}

// Dave_Hoskins hash functions (https://www.shadertoy.com/view/4djSRW)
float Hash11(float p)
{
	vec3 p3  = fract(vec3(p) * 443.897);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 Hash33(vec3 p3)
{
	p3 = fract(p3 * vec3(443.897, 441.423, 437.195));
    p3 += dot(p3, p3.yxz+19.19);
    return fract((p3.xxy + p3.yxx)*p3.zyx);
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
// Scene
//------------------------------------------------------------------------------------------

vec2 U(vec2 d1, vec2 d2) 
{ 
    return (d1.x < d2.x) ? d1 : d2; 
}

vec2 Shape(vec3 p)
{
    // Shape credit to iq (https://www.shadertoy.com/view/Mtfyzl)
    p.xz *= 0.8;
    p.xyz += 1.000*sin(  2.0*p.yzx );
    p.xyz -= 0.500*sin(  4.0*p.yzx );
    float d = length( p.xyz ) - 1.5;
    
	return vec2(d * 0.25, 1.0);
}

vec2 Scene(vec3 p)
{
    vec2 shape = Shape(p);
    vec2 light = vec2(length(p - vec3(0.0, sin(iTime), 0.0) * 3.0) - 0.1, 2.0);
    
    return U(shape, light);
}

//------------------------------------------------------------------------------------------
// Marching
//------------------------------------------------------------------------------------------

vec2 March(in Ray ray)
{
    float depth = NearClip;
    float id    = 0.0;
    
    for(int i = 0; i < MaxSteps; ++i)
    {
        vec3 pos = ray.o + (ray.d * depth);
        vec2 sdf = Scene(pos);
        
        if(sdf.x < Epsilon)
        {
            id = sdf.y;
            break;
        }
        
        if(sdf.x >= FarClip)
        {
            break;
        }
        
        depth += sdf.x;
    }
    
    return vec2(clamp(depth, NearClip, FarClip), id);
}

vec3 SceneNormal(in vec3 pos)
{
	vec2 eps = vec2(0.001, 0.0);
    return normalize(vec3(Scene(pos + eps.xyy).x - Scene(pos - eps.xyy).x,
                          Scene(pos + eps.yxy).x - Scene(pos - eps.yxy).x,
                          Scene(pos + eps.yyx).x - Scene(pos - eps.yyx).x));
}

//------------------------------------------------------------------------------------------
// Local Thickness
//------------------------------------------------------------------------------------------

vec3 GenerateSampleVector(in vec3 norm, in float i)
{
	vec3 randDir = normalize(Hash33(norm + i));
    return MirrorVector(randDir, norm);
}

float CalculateThickness(in vec3 pos, in vec3 norm)
{
    // Perform a number of samples, accumulate thickness, and then divide by number of samples.
    float thickness = 0.0;
    
    for(float i = 0.0; i < SSSThicknessSamples; ++i)
    {
        // For each sample, generate a random length and direction.
        float sampleLength = Hash11(i) * SSSSampleDepth;
        vec3 sampleDir = GenerateSampleVector(-norm, i);
        
        // Thickness is the SDF depth value at that sample point.
        // Remember, internal SDF values are negative. So we add the 
        // sample length to ensure we get a positive value.
        thickness += sampleLength + Scene(pos + (sampleDir * sampleLength)).x;
    }
    
    // Thickness on range [0, 1], where 0 is maximum thickness/density.
    // Remember, the resulting thickness value is multipled against our 
    // lighting during the actual SSS calculation so a value closer to 
    // 1.0 means less absorption/brighter SSS lighting.
    return clamp(thickness * SSSThicknessSamplesI, 0.0, 1.0);
}

//------------------------------------------------------------------------------------------
// Render
//------------------------------------------------------------------------------------------

vec3 Sample(
    in    Ray   ray, 
    inout vec3  normal, 
    inout float depth,
    inout float id,
    inout float thickness)
{
    vec3 color = vec3(0.0);
    vec2 march = March(ray);
    
    depth = march.x;
    id    = march.y;
    
    if(depth < FarClip)
    {
        vec3 pos = ray.o + (ray.d * depth);
        
        normal    = SceneNormal(pos);
        thickness = CalculateThickness(pos, normal);
        color     = vec3(thickness);
    }
    
    return color;
}

//------------------------------------------------------------------------------------------
// Main
//------------------------------------------------------------------------------------------

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    UpdateParameters();
    
    vec2 uv = fragCoord / iResolution.xy;
    Ray ray = Ray_LookAt(uv, CameraPos(), vec3(0.0, -0.25, 0.0));
    
    vec3  normal    = vec3(0.0, 1.0, 0.0);
    float depth     = 0.0;
    float surfID    = 0.0;
    float thickness = 1.0;
    
    vec3 color = Sample(ray, normal, depth, surfID, thickness);
    
    fragColor.r = clamp(depth / FarClip, Epsilon, 1.0);
    fragColor.g = thickness;
    fragColor.b = surfID;
    fragColor.a = float(PackNormal(normal, 14u));
}
