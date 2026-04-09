void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 p = vec3(fragCoord/iResolution.xy, 0);

    p *= 1.68;
    
    p.z += texture(iChannel0, (p + iTime*0.1) * 0.3).r;
    
    vec3 col = texture(iChannel0, p).rrr;
	col += texture(iChannel0, p * 2.).rrr;
    col += texture(iChannel0, p * 4.).rrr;
    col += texture(iChannel0, p * 8.).rrr;
    
    col *= 0.25;
    fragColor = vec4(col,1.0);
}
