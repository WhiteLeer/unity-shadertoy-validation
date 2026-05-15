#define T iTime
#define PI 3.141596
#define TAU 6.283185
#define S smoothstep
#define s1(v) (sin(v)*.5+.5)


float noise(vec2 p){
  return texture(iChannel0, p).r;
}

float fbm(vec2 p){
  float amp = 1.;
  float n = 0.;
  for(float i =0.;i<6.;i++){
    n += noise(p)*amp;
    amp *= .5;
    p *= 2.;
  }
  return n;
}



void mainImage(out vec4 O, in vec2 I){
  vec2 R = iResolution.xy;
  vec2 uv = (I*2.-R)/R.y;

  O.rgb *= 0.;
  O.a = 1.;
  vec3 col = vec3(0);


  vec2 disstortionSpeed = vec2(0.,.06);
  float disstortionScale = .1;

  float n = fbm(uv*disstortionScale+disstortionSpeed*T);
  vec2 uv3 = uv + n;
  float disstortionPower = 1.;
  uv3 = pow(uv3, vec2(disstortionPower));

  float disstortionAmount = .3;
  uv = mix(uv, uv3, disstortionAmount);

  
  float d = abs(uv.y);
  float glow = pow(.1/d,2.);

  vec3 c = s1(vec3(3,2,1)+abs(uv.x)*2.-T);


  col += tanh(c*glow);


  O.rgb = col;
}
