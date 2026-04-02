// Water Toon Torrent
// by Leon Denise
// 2023/08/19

#define R iResolution.xy
#define ss(a,b,t) smoothstep(a,b,t)
float gyroid (vec3 seed) { return dot(sin(seed),cos(seed.yzx)); }

float fbm (vec3 seed)
{
    float result = 0., a = .5;
    for (int i = 0; i < 6; ++i, a /= 2.) {
        seed.x += iTime*.01/a;
        seed.z += result*.5;
        result += gyroid(seed/a)*a;
    }
    return result;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = (2.*fragCoord-R)/R.y;
    float count = 2.;
    float shades = 3.;
    float shape = abs(fbm(vec3(p*.5, 0.)))-iTime*.1-p.x*.1;
    float gradient = fract(shape*count+p.x);
    vec3 blue = vec3(.459,.765,1.);
    vec3 tint = mix(blue*mix(.6,.8,gradient), vec3(1), round(pow(gradient, 4.)*shades)/shades);
    vec3 color = mix(tint, blue*.2, mod(floor(shape*count), 2.));
    fragColor = vec4(color,1.0);
}
