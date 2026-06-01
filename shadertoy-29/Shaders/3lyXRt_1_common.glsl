#define DIST_MIN 1e-5
#define DIST_MAX 1e+5 

#define OBJECT_TYPE_NONE -1
#define OBJECT_TYPE_PLANE 0
#define OBJECT_TYPE_SPHERE 1

struct Frame {
    vec3 X, Y, Z;
};

struct Ray {
    vec3 origin;
    vec3 dir;
};

struct Sphere 
{
	vec3 center;
	float radius;
    vec3 col;
};
    
struct Plane {
    vec3 normal;
    float offset;
    vec3 col;
};
    
// ===== SCENE =====
#define PLANE_COUNT 3
#define SPHERE_COUNT 2
    
Frame CAMERA = Frame(vec3(1, 0, 0), vec3(0, 1, 0), vec3(0, 0, 1));
vec3 EYE_POS = vec3(0, 1.0, -5.0);
const float NEAR_DISTANCE = 2.0f;
const float FAR_DISTANCE = 50.0f;

const vec4 DEFAULT_COLOR = vec4(.45, .85, .92, 1);
const vec3 LIGHT_DIRECTION = normalize(vec3(0.5, -1.0, 1.0));

const Plane[PLANE_COUNT] planes = Plane[](
    Plane(vec3(0.0, 1.0, 0.0), 3.0, vec3(0.1, 0.1, 0.1)),
    Plane(vec3(1.0, 0.0, 0.0), 5.0, vec3(0.9, 0.15, 0.15)),
    Plane(vec3(0.0, 0.0, -1.0), 10.0, vec3(0.0, 0.22, 0.6)));
const Sphere[SPHERE_COUNT] spheres = Sphere[](
    Sphere(vec3(-1.0, 1.0, 11.0), 2.0, vec3(1.0, 0.0, 0.0)),
	Sphere(vec3(3.0, -2.5, 8.0), 1.0, vec3(0.0, 1.0, 0.0)));
    
// struct for remembering intersected object
struct ISObj 
{
	float dist;  // distance to the object
	int type;    // type (-1=nothing,0=plane, 1=sphere)
	int id;      // object ID
};
    
ISObj intersectPlane(in Plane p, in Ray r, in int id) {
    float t = - (p.offset + dot(r.origin, p.normal)) / dot(r.dir, p.normal);
    
    if (t < 0.0) {
        return ISObj(DIST_MAX, OBJECT_TYPE_NONE, -1);
    } else {
    	return ISObj(t, OBJECT_TYPE_PLANE, id);
    }

}
    
ISObj intersectSphere(in Sphere s, in Ray r, in int id) {
    vec3 offset = (r.origin - s.center);
	float a = dot(r.dir, r.dir);
    float b = 2.0 * dot(offset, r.dir);
    float c = dot(offset, offset) - s.radius * s.radius;
    
    float det = sqrt(b*b - 4.0*a*c);
    
    if (det < 0.0) {
        return ISObj(DIST_MAX, OBJECT_TYPE_NONE, -1);
    } else {
        float t = min(- b - det, - b + det) / (2.0 * a);
    	return ISObj(t, OBJECT_TYPE_SPHERE, id);
    }

}

vec3 computeSphereNormal(in Sphere s, in Ray r, in float dist) {
    return normalize((r.origin + r.dir * dist) - s.center);
}

vec2 projectOnScreen(vec3 eye, vec3 point) {
	vec3 toPoint = (point - eye);
    point = (point - toPoint * (1.0 - NEAR_DISTANCE / dot(toPoint, CAMERA.Z)));
    point -= eye + NEAR_DISTANCE * CAMERA.Z;
    return point.xy;
}

