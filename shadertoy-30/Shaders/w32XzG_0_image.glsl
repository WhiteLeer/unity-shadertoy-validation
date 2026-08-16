// from https://www.shadertoy.com/view/WX2XDm
// and https://www.shadertoy.com/view/w3BSWz

#define R        iResolution.xy 
#define H(v)     fract(1e4*sin(1e4*(i)))
#define hue(v)  ( .6 + .6 * cos( 6.3*(v)  + vec4(0,23,21,0)  ) )

float _D;

float push_hole(vec2 U )                                //  from https://www.shadertoy.com/view/WX2XDm
{
    float D = .15,                                      // push distance
          n = 2.;                                       // slope after push: "back to normal" invdistance
    vec2 M = iMouse.xy;
    if (length(M)>10.) M/=R, D = M.y, n = 1./(.01+M.x); // mouse control

    _D = D /= length(U);                                // --- pull original parameterization falling in this pixel
    return D > 1. ? 0. : pow( 1.-pow(D,n), 1./n );      // concentration
}    

void mainImage( out vec4 O, vec2 u )
{
    vec2  V,P,
          U = ( 2.*u - R ) / R.y;        
    float t = iTime/4., v,i, d=1.;

    for( O*=i; i++ < 2e2; ) {
        P = ( vec2( cos(t+i*17.), sin(t*1.3-i*3.) ) + vec2(sin(-t*1.5+i*13.),cos(t*2.1-i*7.) ) )/2. *R/R.y, // bubble coord
        V = U - P,                                              // local coords in bubble
        v = push_hole(V);                                       // repulsion coefficient
        d = min(d,abs(_D-1.)/min(1.,fwidth(_D)));               // contour
        //if (v==0.) O += .1;//.2*hue(i/1e2);                
        //if (v==0. && i==10.) O.r++;
        if (v==0.&& O == O-O ) O = .3+.8*hue(i/1e2);            // bubble color
                            // O = 1.5*fract(1e4*sin(i*vec4(R,17.-R)));
        U = P + v*V;                                            // push parameterization around bubble
    }
    O *=  smoothstep(.0, 1.5, d);
}