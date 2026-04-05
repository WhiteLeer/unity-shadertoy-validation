
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    
    vec4 id00 = texture(iChannel0, (fragCoord+vec2(0,0))/iResolution.xy);
    vec4 id01 = texture(iChannel0, (fragCoord+vec2(0,1))/iResolution.xy);
    vec4 id10 = texture(iChannel0, (fragCoord+vec2(1,0))/iResolution.xy);
    vec4 id11 = texture(iChannel0, (fragCoord+vec2(1,1))/iResolution.xy);
    
    bool noLine = 
        int(id00.a) == int(id01.a) &&
        int(id10.a) == int(id11.a) &&
        int(id00.a) == int(id10.a) &&
        0.1 < dot(id00.xyz, id10.xyz) &&
        0.1 < dot(id10.xyz, id11.xyz);

    
    
    vec4 tmp = texture(iChannel0, uv);

    int id = int(tmp.a);
    float diffuse = fract(tmp.a);

    vec3 baseColor = 0.5*(vec3((id>>2)&1,(id>>1)&1,id & 1)+vec3(1));
    if(id==0) {
        diffuse = 1.0;
        baseColor = vec3(0.5, 0.7, 1.0);
    }
  
    int m = int(0.5*iTime)%6;
    
    if(m == 0) {
        // Regular rendering
	    fragColor = vec4(max(0.3, diffuse) * baseColor, 1.0);
    }
    else if(m==1) {
        // Outlines between objects
	    fragColor = vec4(noLine ? vec3(0.7) : vec3(0), 1);
    }
    else if(m==2) {
        // Outlines and object basecolor
	    fragColor = vec4(noLine ? vec3(0.7) + 0.3*baseColor : vec3(0), 1);
    }
    else if (m==3) {
        // Outlines and object base color binary shaded
	    fragColor = vec4(noLine ? vec3(diffuse < 0.2 ? 0.5 : 0.7) + 0.3*baseColor : vec3(0), 1);
    }
    else if (m==4) {
        // Outlines and lines between shadow and non-shadow
        noLine =
            noLine &&
            abs(fract(id00.a)-fract(id10.a)) < 0.1 &&
            abs(fract(id00.a)-fract(id01.a)) < 0.1 &&
            abs(fract(id10.a)-fract(id11.a)) < 0.1 &&
            abs(fract(id01.a)-fract(id11.a)) < 0.1;
        
        fragColor = vec4(noLine ? vec3(diffuse < 0.2 ? 0.5 : 0.7) + 0.3*baseColor : vec3(0), 1);
    }
    else {
        // Outlines and raaster shading
        const float rasterSize = 8.0;
        float raster = 0.2 + 0.6*length(mod(fragCoord.xy, vec2(rasterSize))/rasterSize-vec2(0.5));
	    fragColor = vec4(noLine ? vec3(diffuse < raster ? 0.5 : 0.7) + 0.3*baseColor : vec3(0), 1);
    }
}
