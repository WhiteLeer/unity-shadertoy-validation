// KABOOM
// (c) Hazel Quantock 2018
// This work is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. http://creativecommons.org/licenses/by-nc-sa/4.0/

// Adapted from https://youtu.be/fE-uDqBpXxI by Cody Winchester


// Smooth perlin-style noise
float Kapow( vec3 p )
{
    p = floor(p) + smoothstep( 0., 1., fract(p) );
    return texture(iChannel0,(p+.5)/32.).r;
}


// Voronoi pattern, distance to closest node in a field of randomly placed nodes
float Kaboom( vec3 p )
{
    ivec3 ip = ivec3(floor(p));
    p = fract(p);
    
    float closest = 10.;
    
    float randomness = .7; const int kernel = 2;
//    float randomness = 1.3; const int kernel = 3; // randomness above .7 need a kernel above 2
    
    for ( int k = 0; k <= kernel; k++ )
    {
        for ( int j = 0; j <= kernel; j++ )
        {
            for ( int i = 0; i <= kernel; i++ )
            {
                vec3 rand = texelFetch( iChannel0, (ip + ivec3(i,j,k))&31, 0 ).gba; // 4-channel map seems as slow as the 1 channel map
                vec3 dp = p - vec3(i,j,k) + float(kernel)*.5 + (rand-.5)*randomness;
                float d = length(dp);
                
                closest = min( closest, d );
            }
        }
    }
    return closest*closest;
}


// Signed Distance Field
float Fraggaboom( vec3 p, float r, vec3 s )
{
    p /= r;
    return r*((length(p) - 1.)*.8 - .5*mix( Kapow(2.*(p+s)), 1.-Kaboom(1.*(p+s)), .8 ));
}


// Colour Pattern
float Badaboom( vec3 p, float r, vec3 s, float m )
{
    p /= r;
    // return a value from 0 to 1 for colouring
    // 0 = crevices, 1 = protrusions - but with some noise to make it more interesting
    return mix(
        		1.-Kapow(2.*(p+s)), // flip it - so we can push further
        		mix(
					1.-Kaboom(1.*(p+s)),
                    1.-Kaboom(5.*(p+s)),
                    .2
                ),
        	m );
}


void mainImage( out vec4 fragColour, in vec2 fragCoord )
{
    float scale = sqrt(fract(iTime/3.));
    vec3 uvwOffset = vec3(0,2,-1)*sqrt(fract(iTime/3.))*2.4 + floor(iTime/3.);
    
    vec3 pos = vec3(2.*(iMouse.xy-iResolution.xy*.5)/iResolution.y,-3);
    vec3 ray = vec3((fragCoord-iResolution.xy*.5)/iResolution.y,1.);
    
    vec3 camK = normalize(vec3(0)-pos);
    vec3 camI = normalize(cross(vec3(0,1,0),camK));
    vec3 camJ = cross(camK,camI);
    
    ray = ray.x*camI+ray.y*camJ+ray.z*camK;

    ray = normalize(ray);
    
    // find the size in scene units of the gap between adjacent rays, as a factor of distance
    float pixelSizePerMetre = length(vec2(length(dFdx(ray)),length(dFdy(ray))));
    
	float t = 0.;
	float lastt = 0.;
    float h = 0.;
    float smallesth = 1e30;
    float closestt = 0.;
    float sdf = 0.;
    float lastsdf = 0.;
    for ( int i=0; i < 200; i++ )
    {
    	float epsilon = pixelSizePerMetre*t;
        lastsdf = sdf;
        sdf = Fraggaboom(pos+ray*t,scale,uvwOffset);
        h = sdf + epsilon*.5; // shrink sdf by the average of the precision we'll end at
        if ( h < epsilon ) break;
        if ( h < smallesth ) { closestt = t; smallesth = h; }
        lastt = t;
        t += h;
    }
    
   	float epsilon = pixelSizePerMetre*t;
    if ( h < epsilon*2. )
    {
        // do the last step with improved precision
        // take the last 2 samples as a guide to where the surface is (assume it's a plane at this scale)
        t = mix( lastt, t, (0.-lastsdf)/(sdf - lastsdf) );
    }
    else if ( t < 1e10 ) // if we didn't reach the sky, pick the best intersection we've got
    {
        t = closestt;
    }
    else
    {
        // background
        fragColour = vec4(.03,.05,.07,1) * (1.-.6*sin(5.*fragCoord.y/iResolution.y));
        return;
    }
    
	pos = pos+ray*t;
    
    // rim-lit parts
    // since we want n.ray, we can just use the last 2 sdf samples! HAHAHA!
    //        float nDotR = (lastsdf-sdf)/lastsdf; // difference between last 2 samples / distance between them
    // woah, lots of noise on that!
    float d = .1;
    float nDotR = (Fraggaboom(pos-.5*d*ray,scale,uvwOffset) - Fraggaboom(pos+.5*d*ray,scale,uvwOffset))/d;
    // d = .01 => moire? is that the texture interpolation resolution?        

    //float rim = pow( max(0.,1.-nDotR), 10. ); // this creates a really badly aliased edge
    float rim = smoothstep(.2,.05,nDotR); // more of an outline

    fragColour.rgb = mix( vec3(.3,.04,0), vec3(10,2.5,1), rim );

    // solid orange bits
    fragColour.rgb = mix( vec3(.99,.25,0), fragColour.rgb, step( .55, Badaboom( pos, scale, uvwOffset, .7 ) ) );
    
    // black parts (slightly different version of the noise
    fragColour.rgb = mix( vec3(.01), fragColour.rgb, step( .42, Badaboom( pos, scale*1.05, uvwOffset, .5 ) ) );
    
    fragColour.a = 1.;
    
    // fake a low fps
//    if ( (iFrame&3) != 0 ) fragColour = texelFetch( iChannel1, ivec2(fragCoord), 0 );
}

