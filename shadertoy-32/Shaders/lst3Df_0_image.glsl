vec3 srgb2lin(vec3 c) { return c*c; }
vec3 lin2srgb(vec3 c) { return sqrt(c); }

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
	
    vec3 s0 = srgb2lin(texture( iChannel0, uv, -10.0 ).rgb);
    vec3 s1 = srgb2lin(texture( iChannel1, uv, -10.0 ).rgb);

    vec3 s2 = srgb2lin(texture( iChannel2, uv, -10.0 ).rgb);
    vec3 s3 = srgb2lin(texture( iChannel3, uv, -10.0 ).rgb);

    //fragColor = vec4( lin2srgb(s0), 1.0 ); return; //DEBUG
    //fragColor = vec4( lin2srgb(s2), 1.0 ); return; //DEBUG
    //
    //fragColor = vec4( lin2srgb(s1), 1.0 ); return; //DEBUG
    //fragColor = vec4( lin2srgb(s2), 1.0 ); return; //DEBUG
    
    fragColor = vec4( lin2srgb( min( s1, s3 ) ), 1.0 ); //octagon
    //fragColor = vec4( lin2srgb( max( s1, s3 ) ), 1.0 ); //star
}

