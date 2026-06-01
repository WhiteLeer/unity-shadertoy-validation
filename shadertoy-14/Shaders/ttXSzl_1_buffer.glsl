struct Ray
{
    vec3 o;
    vec3 d;
};

    
float intersectSphere(out vec3 normal,
	                  in Ray v,
                      in vec3 o,
                      in float r2)
{
    vec3 g = v.o - o;
    
    //<g + t*v.d, g + t*v.d> = r^2
    //<g,g> - r^2 + 2*t*<g,v.d> + t^2 <v.d,v.d> = 0

    float a = dot(v.d, v.d);
    float b = 2.0*dot(g, v.d);
    float c = dot(g, g) - r2;
    
    float disc = b*b - 4.0*a*c;
    if(disc < 0.0) return -1.0;
    
    float d = sqrt(disc);
    float t0 = (-b - d)/(2.0*a);
    
    vec3 w = g + t0*v.d;
    normal = normalize(w);

    return t0;
}
   
float intersectCube(out vec3 normal,
                    in Ray r,
                    in vec3 o,
                    in vec3 s)
{
    vec3 rcp = 1.0/r.d;
    vec3 a = rcp*(o - r.o);
    vec3 ta = a - abs(rcp)*s;
    vec3 tb = a + abs(rcp)*s;



    normal = vec3(0,1,1);
    
    float tn = max(max(ta.x, ta.y), ta.z);
    float tf = min(min(tb.x, tb.y), tb.z);
    if( tf < max(0.001, tn)) {
        return -1.0;
    }
    
    // find channel that is less than the two other channels.
    // flip sign to choose correct face.
    vec3 lessThan1 = step(ta.yzx, ta.xyz);
    vec3 lessThan2 = step(ta.zxy, ta.xyz);
    normal = -sign(r.d)*lessThan1*lessThan2;
   
    return tn;
}

float intersectCylinder(out vec3 normal,
                        in Ray r,
                        in vec3 o,
                        float hl,
                        float r2)
{
    vec2 g = r.o.xy - o.xy;
    
    //<g + t*v.d, g + t*v.d> = r^2
    //<g,g> - r^2 + 2*t*<g,v.d> + t^2 <v.d,v.d> = 0

    float a = dot(r.d.xy, r.d.xy);
    float b = 2.0*dot(g.xy, r.d.xy);
    float c = dot(g.xy, g.xy) - r2;
    
    float disc = b*b - 4.0*a*c;
    if(disc < 0.0) return -1.0;

    
    float d = sqrt(disc);
    float t0 = (-b - d)/(2.0*a);
    float t1 = (-b + d)/(2.0*a);

    float rcp = 1.0/r.d.z;
    float aa = rcp*(o - r.o).z;
    float ta = aa - abs(rcp)*hl;
    float tb = aa + abs(rcp)*hl;

    // cylinder is between near and far cap
    if(ta <= t0 && t0 <= tb) {
        vec2 w = g + t0*r.d.xy;
	    normal = normalize(vec3(w,0));
        return t0;
    }
            
    // near cap is inside infinite cylinder
    if(t0 < ta && ta < t1) {
     	normal = vec3(0,0,-sign(r.d.z));
        return ta;
    }

    return -1.0;
}

float intersectPlane(out vec3 normal,
                     in Ray r,
                     in vec3 n,
                     float d)
{
    normal = n;
    return -(d - dot(r.o, n))/dot(r.d, n);
}


float castRay(out vec3 n, out int id, in Ray r)
{
    id = 0;
    float t = 1e37;
    for(int k=0; k<3; k++) {
        for(int j=0; j<3; j++) {
            for(int i=0; i<3; i++) {
                vec3 nn;
                float tt;

                int kk = i+j+k;
                
                vec3 o = vec3(i-1, j-1, k-1);
                
                if((kk % 3)==0) {
	                tt = intersectSphere(nn, r, o, 0.45*0.45);
                }
                else if((kk %3)==1) {
                    tt = intersectCylinder(nn, r, o, 0.45, 0.45*0.45);
                }
                else {
	                tt = intersectCube(nn, r, o, vec3(0.45));
                }
                 if(0.0 < tt && tt < t) {
                    t = tt;
                    n = nn;
                    id = 3*(3*k+j) + i + 2; 
                }
            }
        }
    }
 
    {
        vec3 nn;
        float tt = intersectPlane(nn, r, vec3(0,1,0), 2.0);
        if(0.0 < tt && tt < t) {
            t = tt;
            n = nn;
            id = 1;
        }
    }
    
    return t < 1e37 ? t : -1.0;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    float ww = 0.3;
    float c0 = cos(ww*iTime);
    float s0 = sin(ww*iTime);
    float c1 = cos(ww*iTime+0.6);
    float s1 = sin(ww*iTime+0.6);
    
    float w = 2.0/max(iResolution.x, iResolution.y);
    vec3 q = vec3(w*(fragCoord.xy - 0.5*iResolution.xy), -1.0);
    
    Ray r;

    r.d.x = c0*q.x - s0*q.z;
    r.d.y = q.y+0.0000001;	// Quick-fix for rcp is nan in box.
    r.d.z = s0*q.x + c0*q.z;
    r.d = normalize(r.d);

    r.o = 5.0*vec3(-s0,0,c0);
   
    int id;
	vec3 n;
    float t = castRay(n, id, r);

    if(0.0 < t) {
        vec3 lp = 7.0*vec3(-s1, 0.75, c1);
        
        Ray s;
        s.o = r.o + t*r.d;
        s.d = normalize(lp-s.o);
        //s.o += 0.01*s.d;
        
        vec3 foo;
        int bar;
        float tt = castRay(foo, bar, s);
        bool inShadow = 0.0 < tt;
        
        float diffuse = inShadow ? 0.0 : dot(s.d, n);
        
    	fragColor = vec4(n, float(id) + fract(max(0.0, diffuse)));
    }
    else {
	    fragColor = vec4(0,0,1,0);
    }
}
