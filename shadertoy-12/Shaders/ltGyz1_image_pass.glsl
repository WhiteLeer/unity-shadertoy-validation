// KABOOM
// (c) Hazel Quantock 2018
// This work is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. http://creativecommons.org/licenses/by-nc-sa/4.0/

// Adapted from https://youtu.be/fE-uDqBpXxI by Cody Winchester

void mainImage( out vec4 fragColour, in vec2 fragCoord )
{
    fragColour = texelFetch( iChannel0, ivec2(fragCoord), 0 );
    
    // add bloom
    float weights = 0.;
    vec3 bloom = vec3(0);
    const int kernel = 10;
    for ( int j=-kernel; j <= kernel; j++ )
    {
        for ( int i=-kernel; i <= kernel; i++ )
        {
            float weight = pow( smoothstep(float(kernel+1),0.,length(vec2(i,j))), 1. );
            bloom += texelFetch( iChannel0, ivec2(fragCoord)+ivec2(i,j), 0 ).rgb * weight;
            weights += weight;
        }
	}
    
    fragColour.rgb += bloom*.3 / weights;

    // gamma correct
    fragColour.rgb = pow(fragColour.rgb,vec3(1./2.2));
    fragColour.a = 1.;
}
