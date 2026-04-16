#define K 3//int(iMouse.x/iResolution.x*8.)

#define KERN_TEX(a, b) texture(iChannel0, (fragCoord+vec2(i-a, j-b))/iResolution.xy).rgb

#define GRAY(a) dot(a, vec3(.299, .587, .114))

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    float sectorSz=float(K*K+2*K+1);
    
    //compute 4 sector means
    vec3 u0=vec3(0.), u1=u0, u2=u0, u3=u0;
    for(int i=0;i<=K;i++){
        for(int j=0;j<=K;j++){
            u0+=KERN_TEX(K, K);
            u1+=KERN_TEX(0, K);
            u2+=KERN_TEX(K, 0);
            u3+=KERN_TEX(0, 0);
        }
    }
    u0/=sectorSz, u1/=sectorSz, u2/=sectorSz, u3/=sectorSz;
    vec4 u=vec4(GRAY(u0), GRAY(u1), GRAY(u2), GRAY(u3));
    
    //compute those sectors variance
    vec4 var=vec4(0.);
    for(int i=0;i<=K;i++){
        for(int j=0;j<=K;j++){
            vec4 v=vec4(
                GRAY(KERN_TEX(K, K)),
                GRAY(KERN_TEX(0, K)),
                GRAY(KERN_TEX(K, 0)),
                GRAY(KERN_TEX(0, 0))
            )-u;
            var+=v*v;
        }
    }
    
    //set pix to mean of sector with min variance
    float m=min(var.x, min(var.y, min(var.z, var.w)));
    fragColor=vec4(
        m==var.x ? u0 :
        m==var.y ? u1 : 
        m==var.z ? u2 :
        m==var.w ? u3 :
        (u0+u1+u2+u3)*.25,
        1.
    );
}
