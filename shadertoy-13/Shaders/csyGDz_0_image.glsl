// Toon flame (c) Kristian Sivonen (ruojake)
// CC BY-SA 4.0 (https://creativecommons.org/licenses/by-sa/4.0/)

#define FK(x) floatBitsToInt(cos(x))^floatBitsToInt(x)

float hash12(vec2 p)
{
    int x = FK(p.x);
    int y = FK(p.y);
    return float((x*x-y)*(y*y+x)-x) / 2.14e9;
}

vec2 hash22(vec2 p)
{
    return vec2(hash12(p), hash12(p * 13.321 - 114.411));
}

mat2 rot(float a)
{
    float s = sin(a), c = cos(a);
    return mat2(c,-s,s,c);
}

float ball(vec2 p)
{
    vec2 i = floor(p);
    float minDist = 10000.;
    for(float x = -2.; x <= 2.; x += 1.)
    for(float y = -2.; y <= 2.; y += 1.)
    {
        vec2 c = i + vec2(x, y);
        vec2 h = hash22(c);
        float r = fract(h.x + .6541) * .5 + .3;
        h *= rot(iTime * (fract(r + .134) * 8. - 4.));
        
        minDist = min(minDist, length(p - (c + h)) - r);
    }
    return minDist;
}

float flame(vec2 p)
{
    float t = iTime * 3.1415 * .25;
    vec2 o = vec2(0,-.25);
    float d = 10000.;
    for (float i = 0.; i < 1.; i += 1./8.)
    {
        float lt = fract(t + i);
        float r = sqrt(1.-lt) * .2 * min(lt * 2., 1.);
       
        d = min(d, (length(p-vec2(sin(t - lt) * (.3 / (lt+1.) + .2),lt*lt*.6)-o) - r) * 10. * pow(2.-lt,4.));
    }
    return d;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord - iResolution.xy * .5)/iResolution.y;

    float d = ball(uv * 40. - vec2(0, iTime * 10.));
    float d2 = 1.-ball(uv * 10. - vec2(0, iTime * 7.));
    float fw = fwidth(d);
    float flm = d - d2 - flame(uv);
    vec3 col = mix(vec3(.05,.15,.2), vec3(1,.6,.05), smoothstep(-fw, fw, flm));
    col = mix(col, vec3(1., .9,.4), smoothstep(-fw, fw, flm - 3.));
    fragColor = vec4(col,1.0);
}
