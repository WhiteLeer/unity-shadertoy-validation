// created by florian berger (flockaroo) - 2018
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// oil paint brush drawing

// calculating and drawing drawing the brush strokes
// ...reimplementation of shaderoo.org geometry version, but purely in fragment shader
// original geometry version of this: https://shaderoo.org/?shader=N6DFZT

#define COLORKEY_BG
#define QUALITY_PERCENT 85
//#define CANVAS

#define Res (iResolution.xy)
#define Res0 vec2(textureSize(iChannel0,0))
#define Res1 vec2(textureSize(iChannel1,0))

#define PI 3.1415927

#define N(v) (v.yx*vec2(1,-1))

vec4 getRand(vec2 pos)
{
    return textureLod(iChannel1,pos/Res1,0.);
}

vec4 getRand(int idx)
{
    ivec2 rres=textureSize(iChannel1,0);
    idx=idx%(rres.x*rres.y);
    return texelFetch(iChannel1,ivec2(idx%rres.x,idx/rres.x),0);
}

float SrcContrast = 1.4;
float SrcBright = 1.;

vec4 getCol(vec2 pos, float lod)
{
    // use max(...) for fitting full image or min(...) for fitting only one dir
    vec2 uv = (pos-.5*Res)*min(Res0.y/Res.y,Res0.x/Res.x)/Res0+.5;
    vec2 mask = step(vec2(-.5),-abs(uv-.5));
    vec4 col = clamp(((textureLod(iChannel0,uv,lod)-.5)*SrcContrast+.5*SrcBright),0.,1.)/**mask.x*mask.y*/;
    #ifdef COLORKEY_BG
    vec4 bg=textureLod(iChannel2,uv,lod+.7);
    col = mix(col,bg,dot(col.xyz,vec3(-.6,1.3,-.6)));
    #endif
    return col;
}

uniform float FlickerStrength;

vec3 getValCol(vec2 pos, float lod)
{
    return getCol(pos,1.5+log2(Res0.x/600.)).xyz;
    return getCol(pos,1.5+log2(Res0.x/600.)).xyz*.7+getCol(pos,3.5+log2(Res0.x/600.)).xyz*.3;
}

float compsignedmax(vec3 c)
{
    vec3 s=sign(c);
    vec3 a=abs(c);
    if (a.x>a.y && a.x>a.z) return c.x;
    if (a.y>a.x && a.y>a.z) return c.y;
    return c.z;
}

vec2 getGradMax(vec2 pos, float eps)
{
    vec2 d=vec2(eps,0);
    // calc lod according to step size
    float lod = log2(2.*eps*Res0.x/Res.x);
    //lod=0.;
    return vec2(
        compsignedmax(getValCol(pos+d.xy,lod)-getValCol(pos-d.xy,lod)),
        compsignedmax(getValCol(pos+d.yx,lod)-getValCol(pos-d.yx,lod))
        )/eps/2.;
}

vec2 quad(vec2 p1, vec2 p2, vec2 p3, vec2 p4, int idx) 
{
    vec2 p[6] = vec2[](p1,p2,p3,p2,p4,p3);
    return p[idx%6];
}

float BrushDetail = 0.1;

float StrokeBend=-1.;
float BrushSize = 1.;

void mainImage( out vec4 fragColor, vec2 fragCoord )
{
    vec2 pos = fragCoord.xy;
    pos += 4.0*sin(iTime*.5*vec2(1,1.7))*iResolution.y/400.;
    
    float canv=0.;
    canv=max(canv,(getRand(pos*vec2(.7,.03).xy)).x);
    canv=max(canv,(getRand(pos*vec2(.7,.03).yx)).x);
    fragColor=vec4(vec3(.93+.07*canv),1);
    canv-=.5;
    
    int pidx0 = 0;
    
    vec3 brushPos;
    //int layerScalePercent = QUALITY_PERCENT;
    float layerScaleFact=float(QUALITY_PERCENT)/100.;
    float ls = layerScaleFact*layerScaleFact;
    //number of grid positions on highest detail level
    int NumGrid=int(float(0x10000/2)*min(pow(Res.x/1920.,.5),1.)*(1.-ls));
    //int NumGrid=10000;
    float aspect=Res.x/Res.y;
    int NumX = int(sqrt(float(NumGrid)*aspect)+.5);
    int NumY = int(sqrt(float(NumGrid)/aspect)+.5);
    //int pidx2 = NumX*NumY*4/3-pidx;
    int pidx2 /*= NumTriangles/2-pidx*/;
    // calc max layer NumY*layerScaleFact^maxLayer==10. - so min-scale layer has at least 10 strokes in y
    int maxLayer=int(log2(10./float(NumY))/log2(layerScaleFact));
    //maxLayer=8;
    for(int layer = min(maxLayer,11); layer>=0; layer--) // min(...) at beginning - possible crash cause on some systems?
    {
    int NumX2 = int(float(NumX) * pow(layerScaleFact,float(layer))+.5);
    int NumY2 = int(float(NumY) * pow(layerScaleFact,float(layer))+.5);

    // actually -2..2 would be needed, but very slow then...
    //for(int nx=-1;nx<=1;nx++)
    //for(int ny=-1;ny<=1;ny++)
    // replaced the 2 loops above by 1 loop and some modulo magic (possible crash cause on some systems?)
    for(int ni=0;ni<9;ni++)
    {
        int nx=ni%3-1;
        int ny=ni/3-1;
    // index centerd in cell
    int n0 = int(dot(floor(vec2(pos/Res.xy*vec2(NumX2,NumY2))),vec2(1,NumX2)));
    pidx2=n0+NumX2*ny+nx;
    int pidx=pidx0+pidx2;
    brushPos.xy = (vec2(pidx2%NumX2,pidx2/NumX2)+.5)/vec2(NumX2,NumY2)*Res;
    float gridW = Res.x/float(NumX2);
    float gridW0 = Res.x/float(NumX);
    // add some noise to grid pos
    brushPos.xy += gridW*(getRand(pidx+iFrame*123*0).xy-.5);
    // more trigonal grid by displacing every 2nd line
    brushPos.x += gridW*.5*(float((pidx2/NumX2)%2)-.5);
    
    vec2 g; 
    g = getGradMax(brushPos.xy,gridW*1.)*.5+getGradMax(brushPos.xy,gridW*.12)*.5
        +.0003*sin(pos/Res*20.); // add some gradient to plain areas
    float gl=length(g);
    vec2 n = normalize(g);
    vec2 t = N(n);
    
    brushPos.z = .5;

    // width and length of brush stroke
    float wh = (gridW-.6*gridW0)*1.2;
    float lh = wh;
    float stretch=sqrt(1.5*pow(3.,1./float(layer+1)));
    wh*=BrushSize*(.8+.4*getRand(pidx).y)/stretch;
    lh*=BrushSize*(.8+.4*getRand(pidx).z)*stretch;
    float wh0=wh;
    
    wh/=1.-.25*abs(StrokeBend);
    
    wh = (gl*BrushDetail<.003/wh0 && wh0<Res.x*.02 && layer!=maxLayer) ? 0. : wh;
    
    vec2 uv=vec2(dot(pos-brushPos.xy,n),dot(pos-brushPos.xy,t))/vec2(wh,lh)*.5;
    // bending the brush stroke
    uv.x-=.125*StrokeBend;
    uv.x+=uv.y*uv.y*StrokeBend;
    uv.x/=1.-.25*abs(StrokeBend);
    uv+=.5;
    //float s=mix((uv.x-.4)/.6,1.-uv.x,step(.5,uv.x))*5.;
    float s=1.;
    s*=uv.x*(1.-uv.x)*6.;
    s*=uv.y*(1.-uv.y)*6.;
    float s0=s;
    s=clamp((s-.5)*2.,0.,1.);
    vec2 uv0=uv;
    
    // brush hair noise
    float pat = textureLod(iChannel1,uv*1.5*sqrt(Res.x/600.)*vec2(.06,.006),1.).x+textureLod(iChannel1,uv*3.*sqrt(Res.x/600.)*vec2(.06,.006),1.).x;
    vec4 rnd = getRand(pidx);
    
    s0=s;
    s*=.7*pat;
    uv0.y=1.-uv0.y;
    float smask=clamp(max(cos(uv0.x*PI*2.+1.5*(rnd.x-.5)),(1.5*exp(-uv0.y*uv0.y/.15/.15)+.2)*(1.-uv0.y))+.1,0.,1.);
    s+=s0*smask;
    s-=.5*uv0.y;
#ifdef CANVAS
    s+=(1.-smask)*canv*1.;
    s+=(1.-smask)*(getRand(pos*.7).z-.5)*.5;
#endif
    
    vec4 dfragColor;
    dfragColor.xyz = getCol(brushPos.xy,1.).xyz*mix(s*.13+.87,1.,smask)/**(.975+.025*s)*/;
    s=clamp(s,0.,1.);
    dfragColor.w = s * step(-0.5,-abs(uv0.x-.5)) * step(-0.5,-abs(uv0.y-.5));
    // do alpha blending
    fragColor = mix(fragColor,dfragColor,dfragColor.w);
    }
    pidx0+=NumX2*NumY2;
    }
}


