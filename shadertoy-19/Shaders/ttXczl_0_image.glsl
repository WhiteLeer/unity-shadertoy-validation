// Trying to reprudce the classic screenprinting style

// Most of all of the look comes from the dots() function
// You feed it the luminosity of the image, and then multiply image by the return value


#define CELL_SZ 0.02
#define COL_SEP 0.2
#define STR 1.4

#define LUM_EPS (6.0 )

#define T(u) texture(iChannel0,(u)/iResolution.xy)

#define Neighborhood \
vec3 n = getImg(U + vec2(0.,1.)*LUM_EPS);vec3 s = getImg(U - vec2(0.,1.)*LUM_EPS);vec3 e = getImg(U + vec2(1.,0.)*LUM_EPS);vec3 w = getImg(U - vec2(1.,0.)*LUM_EPS);\
vec3 se = getImg(U + vec2(1.,-1.)*LUM_EPS);vec3 sw = getImg(U - vec2(-1.,-1.)*LUM_EPS);vec3 ne = getImg(U + vec2(1.,1.)*LUM_EPS);vec3 nw = getImg(U + vec2(-1.,1.)*LUM_EPS);


#define rot(j) mat2(cos(j),-sin(j),sin(j),cos(j))
#define pmod(p,j) mod(p,j) - 0.5*j
#define pi acos(-1.)

#define smoothness 0.004

//#define noise(i) texture(iChannel0,vec2(mod((i),256.)/256.,floor(i/256.)/256.))
///  2 out, 2 in...
vec2 hash22(vec2 p)
{
	vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);

}
float noise(vec2 p){
	vec2 fruv = fract(p);
	vec2 fluv = floor(p);
    return mix( 
        mix(
            hash22(fluv).x,
            hash22(fluv + vec2(1,0)).x,
        	fruv.x
        ), 
        mix(
            hash22(fluv + vec2(0,1)).x,
            hash22(fluv + vec2(1,1)).x,
        	fruv.x
        ),
        fruv.y
    );
}


float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }

float sdCoolBall(vec2 uv){
	float sdBall = length(uv) - 0.4; 
    sdBall = opSmoothUnion( sdBall, length(uv + 0.5 + vec2(sin(iTime)*0.1)) - 0.1,0.4 );
    sdBall = opSmoothUnion( sdBall, length(uv - 0.5 + vec2(sin(iTime/2. + cos(iTime))*0.1)) - 0.1,0.4 );
    sdBall = opSmoothUnion( sdBall, length(uv - vec2(-0.5,0.2) + vec2(sin(iTime/2.), cos(iTime+ 4.) )/14.) - 0.04,0.3 );
    //sdBall = opSmoothUnion( sdBall, length(uv - vec2(0.5,-0.4) + vec2(sin(iTime/2. )*0.1,cos(iTime))*0.1) - 0.1,0.4 );
    
    return sdBall;
}

vec3 getImg(vec2 fragCoord){
    vec2 uv = (fragCoord - 0.5*iResolution.xy)/iResolution.y;

    vec3 col = vec3(0.,0.,0.);
    
    vec2 puv = vec2(atan(uv.y,uv.x)/pi + 1.,length(uv));
    
    
    if(puv.x < 0.4)
    	col = vec3(0.2,0.5,0.4)*1.55;
    else if(puv.x < 1.)
    	col = vec3(0.5,0.5,0.9);
    else if(puv.x < 1.4)
    	col = vec3(1.,0.716,0.7);
    else 
    	col = vec3(0.9,0.6,0.6);
    
    //col *= smoothstep(1.,0.,length(uv)/3.);
    
    //uv *= rot(-0.7);
    
    col = mix(col,vec3(1,0.1,0.6),smoothstep(1.,0.,length(abs(uv.y) + 0.)*4. + 0.3));
    
    uv *= rot(-1.2);
    col = mix(col,vec3(1,0.1,0.5),smoothstep(1.,0.,length(abs(uv.y) + 0.)*4. + 0.3));
    
    
    uv *= rot(-1.4);
    
    
    vec3 bc = vec3(1.,0.7,0.6) *mix(vec3(1.),vec3(0.1,0.,0.),smoothstep(0.,1.,uv.x + uv.y*1.5 -0.1 + length(uv)/1.5));
    
    
    float dBalla = sdCoolBall(uv);
        
    float dBallb = sdCoolBall(uv-0.04);
        
    
    col = mix(col,vec3(1,1.,0.9), smoothstep(smoothness,0.,dBallb));
    
    
    col = mix(col,bc, smoothstep(smoothness,0.,dBalla));
    
    
    col = mix(col,vec3(1,0.7,1.),smoothstep(1.,0.,length(uv + vec2(0.13,0.25))*18. + 0.3));
    
    col = mix(col,vec3(1,0.7,1.),smoothstep(1.,0.,length(uv + vec2(0.7,0.4))*14. + 0.3));
    
    
    
    return col;
}


// get avg lum
vec3 getAvg(vec2 U){
    
    float l = 0.4;
    Neighborhood;
    
    vec3 avg = (n + e + w + s + ne + sw + se + nw)/8.;
    
    return avg;

}
    

float dots(vec2 p,float lum){
	float t = 0.;
    vec2 q = p ;
    
    p *= rot(0.25*pi);
    
    
    q /= CELL_SZ/pi;
    // some distortion
    p -= length(sin(q))*normalize(p)*CELL_SZ/6.;
    
    
    p = pmod(p,CELL_SZ);
    p -= length(sin(q))*normalize(p)*CELL_SZ/6.;
    
    float lsz = 0.;
    
    float n = noise(q*10.);
    
    n = pow(n,2.)*0.07;
    lsz = pow(smoothstep(0.,1.,lum*(0.45 +n)),STR)*CELL_SZ*0.6;
    
    float col = smoothstep(0.003,0.,length(p) - lsz);
    //col = mix(col,smoothstep(0.01,0.,sin(q.x)*sin(q.y)* lsz*1. ),0.1);
	
    return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.y;

    vec3 col = vec3(0);
    
    vec3 tex = getImg(fragCoord);
    
    tex = getAvg(fragCoord);
    
    float lum = length(tex);
    
    col = vec3(0.1,0.5,0.9)*0.1;
    col = mix(col,floor(tex/COL_SEP)*COL_SEP,dots(uv,lum));
    
    col = smoothstep(0.,1.,col);
    col = pow(col,vec3(0.4545));
    fragColor = vec4(col,1.0);
}
