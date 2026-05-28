// Copyright Inigo Quilez, 2017 - https://iquilezles.org/
// I am the sole copyright owner of this Work. You cannot
// host, display, distribute or share this Work neither as
// is or altered, in any form including physical and
// digital. You cannot use this Work in any commercial or
// non-commercial product, website or project. You cannot
// sell this Work and you cannot mint an NFTs of it. You
// cannot use this Work to train AI models. I share this
// Work for educational purposes, you can link to it as
// an URL, proper attribution and unmodified screenshot,
// as part of your educational material. If these
// conditions are too restrictive please contact me.

// You can buy a metal print of this shader here:
// https://www.redbubble.com/i/metal-print/Greek-Temple-by-InigoQuilez/39845587.0JXQP

// A basic temple model. No global illumination, all cheated and composed to camera:
//
// - the terrain is false perspective
// - there are two different sun directions for foreground and background. 
// - ambient occlusion is mostly painted by hand
// - bounce lighting is also painted by hand
//
// This shader was made as a continuation to a live coding session I did for the students
// of UPENN. After the initial live coded session I decided to rework it and improve it,
// and that turned out to be a bit of a pain because when looking for the final look I got
// trapped in more local minima that I usually do and it took me a while to leave them. 



void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	ivec2 p = ivec2(fragCoord-0.5);
    
    vec3 col = texelFetch( iChannel0, p, 0 ).xyz;
    
    vec2 q = fragCoord / iResolution.xy;
    col *= 0.8 + 0.2*pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.2 );

    
	fragColor = vec4(col,1.0);
}
