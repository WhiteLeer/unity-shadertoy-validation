/*
    "Grok" by @XorDev
    
    Shared by Musk!
    https://x.com/elonmusk/status/1894427923463246217
*/
void mainImage( out vec4 O, vec2 I)
{
    vec2 r=iResolution.xy, p=(I+I-r)/r.y;
    O=.1/abs(length(p)-.5+.01/(p.xxxx-p.y));
}