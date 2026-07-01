const vec2 blurdir = vec2( 0.0, 1.0 );

const float blurdist_px = 64.0;
const int NUM_SAMPLES = 16;




vec3 srgb2lin(vec3 c) { return c*c; }
vec3 lin2srgb(vec3 c) { return sqrt(c); }

//note: uniform pdf rand [0;1[
float hash12n(vec2 p)
{
	p  = fract(p * vec2(5.3987, 5.4421));
    p += dot(p.yx, p.xy + vec2(21.5351, 14.3137));
	return fract(p.x * p.y * 95.4307);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 blurvec = normalize(blurdir) / iResolution.xy;
    vec2 uv = fragCoord / iResolution.xy;
    float sinblur = ( 0.55 + 0.45 * sin( 5.0 * uv.x + iTime ) );
    float blurdist = (iMouse.z>0.5) ? 100.0 * iMouse.x/iResolution.x : blurdist_px * sinblur;
    
    vec2 p0 = uv - 0.5 * blurdist * blurvec;
    vec2 p1 = uv + 0.5 * blurdist * blurvec;
    vec2 stepvec = (p1-p0) / float(NUM_SAMPLES);
    vec2 p = p0 + (hash12n(uv+fract(iTime))-0.5) * stepvec;
    
    vec3 sumcol = vec3(0.0);
    for (int i=0;i<NUM_SAMPLES;++i)
    {
     	sumcol += srgb2lin( texture( iChannel0, p, -10.0 ).rgb);
        p += stepvec;
    }
    sumcol /= float(NUM_SAMPLES);
    
    fragColor = vec4( lin2srgb(sumcol), 1.0 );
}

