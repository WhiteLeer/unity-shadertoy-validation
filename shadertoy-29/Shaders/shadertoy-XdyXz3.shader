Shader "Shadertoy/XdyXz3_NoiseHoles"
{
    Properties
    {
        [MainTexture] _BaseMap("Texture", 2D) = "white" {}
        [MainColor] _BaseColor("Color", Color) = (1, 1, 1, 1)
        _Cutoff("AlphaCutout", Range(0.0, 1.0)) = 0.5
        _Surface("__surface", Float) = 0.0
        _STResolution("ST Resolution", Vector) = (960, 540, 0.001041667, 0.001851852)
        _STMouse("ST Mouse", Vector) = (0, 0, 0, 0)
        _STTime("ST Time", Float) = 0
        _STFrame("ST Frame", Float) = 0
    }

    SubShader
    {
        Cull Off
        ZWrite Off
        ZTest Always

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            half4 _BaseColor;
            half _Cutoff;
            float _Surface;
            float4 _STResolution;
            float4 _STMouse;
            float _STTime;
            float _STFrame;
        CBUFFER_END

        float st_mod(float x, float y)
        {
            return x - y * floor(x / y);
        }

        float2 st_mod(float2 x, float y)
        {
            return x - y * floor(x / y);
        }

        float3 st_mod(float3 x, float y)
        {
            return x - y * floor(x / y);
        }

//
// Description : Array and textureless GLSL 2D/3D/4D simplex 
//               noise functions.
//      Author : Ian McEwan, Ashima Arts.
//  Maintainer : ijm
//     Lastmod : 20110822 (ijm)
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License. See LICENSE file.
//               https://github.com/ashima/webgl-noise
// 

float3 mod289(float3 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

float4 mod289(float4 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

float4 permute(float4 x) {
     return mod289(((x*34.0)+1.0)*x);
}

float4 taylorInvSqrt(float4 r)
{
  return 1.79284291400159 - 0.85373472095314 * r;
}

float snoise(float3 v)
  { 
  const float2  C = float2(1.0/6.0, 1.0/3.0) ;
  const float4  D = float4(0.0, 0.5, 1.0, 2.0);

// First corner
  float3 i  = floor(v + dot(v, C.yyy) );
  float3 x0 =   v - i + dot(i, C.xxx) ;

// Other corners
  float3 g = step(x0.yzx, x0.xyz);
  float3 l = 1.0 - g;
  float3 i1 = min( g.xyz, l.zxy );
  float3 i2 = max( g.xyz, l.zxy );

  //   x0 = x0 - 0.0 + 0.0 * C.xxx;
  //   x1 = x0 - i1  + 1.0 * C.xxx;
  //   x2 = x0 - i2  + 2.0 * C.xxx;
  //   x3 = x0 - 1.0 + 3.0 * C.xxx;
  float3 x1 = x0 - i1 + C.xxx;
  float3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
  float3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y

// Permutations
  i = mod289(i); 
  float4 p = permute( permute( permute( 
             i.z + float4(0.0, i1.z, i2.z, 1.0 ))
           + i.y + float4(0.0, i1.y, i2.y, 1.0 )) 
           + i.x + float4(0.0, i1.x, i2.x, 1.0 ));

// Gradients: 7x7 points over a square, mapped onto an octahedron.
// The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
  float n_ = 0.142857142857; // 1.0/7.0
  float3  ns = n_ * D.wyz - D.xzx;

  float4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  st_mod(p,7*7)

  float4 x_ = floor(j * ns.z);
  float4 y_ = floor(j - 7.0 * x_ );    // st_mod(j,N)

  float4 x = x_ *ns.x + ns.yyyy;
  float4 y = y_ *ns.x + ns.yyyy;
  float4 h = 1.0 - abs(x) - abs(y);

  float4 b0 = float4( x.xy, y.xy );
  float4 b1 = float4( x.zw, y.zw );

  //float4 s0 = float4(lessThan(b0,0.0))*2.0 - 1.0;
  //float4 s1 = float4(lessThan(b1,0.0))*2.0 - 1.0;
  float4 s0 = floor(b0)*2.0 + 1.0;
  float4 s1 = floor(b1)*2.0 + 1.0;
  float4 sh = -step(h, float4(0.0, 0.0, 0.0, 0.0));

  float4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
  float4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

  float3 p0 = float3(a0.xy,h.x);
  float3 p1 = float3(a0.zw,h.y);
  float3 p2 = float3(a1.xy,h.z);
  float3 p3 = float3(a1.zw,h.w);

//Normalise gradients
  float4 norm = taylorInvSqrt(float4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;

// Mix final noise value
  float4 m = max(0.6 - float4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
  m = m * m;
  return 42.0 * dot( m*m, float4( dot(p0,x0), dot(p1,x1), 
                                dot(p2,x2), dot(p3,x3) ) );
  }

//END ASHIMA /////////////////////////////////////////////////

static const float ST_STEPS = 8.0;
static const float ST_CUTOFF = 0.65; //depth less than this, show white wall
const float2  ST_OFFSET = float2(0.004,0.004); //drop shadow offset

float3 hsv2rgb(float3 c){
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float getNoise(float2 uv, float t){
    
    //given a uv coord and time - return a noise val in range 0 - 1
    //using ashima noise
    
    //octave 1
    float SCALE = 2.0;
    float noise = snoise( float3(uv.x*SCALE + t,uv.y*SCALE + t , 0));
    
    //octave 2 - more detail
    SCALE = 6.0;
    noise += snoise( float3(uv.x*SCALE + t,uv.y*SCALE , 0))* 0.2 ;
    
    //move noise into 0 - 1 range    
    noise = (noise/2. + 0.5);
    
    //make deeper rarer
    //noise = pow(noise,2.);
    
    return noise;
    
}

float getDepth(float n){
 
    //given a 0-1 value return a depth,
    //e.g. distance into the hole
    
    //remap remaining non-cutoff region to 0 - 1
	float d = (n - ST_CUTOFF) / (1. - ST_CUTOFF); 
        
    //step it
    d = floor(d*ST_STEPS)/ST_STEPS;
    
    return d;
    
}

float4 RenderNoiseHoles(float2 fragCoord)
{
	float2 uv = fragCoord.xy / _STResolution.x;
    float t = _STTime * 0.3;    
    float3 col = float3(0.0, 0.0, 0.0);
    
   	float noise = getNoise(uv, t);
    
    if (noise < ST_CUTOFF){
        
        //white wall
        col = float3(1.,1.,1.);//white
        
    }else{
    
		float d = getDepth(noise);
        
        //calc HSV color
        float h = d + 0.2; //rainbow hue
        float s = 0.5;
        float v = 0.9 - ( d*0.6); //deeper is darker
        
       	//add bevel
        
       	//get depth at offset position        
        float noiseOff = getNoise(uv + ST_OFFSET, t);
        float dOff = getDepth(noiseOff);
       	
        //if depth of this pixel (d) is less (closer) than offset pixel (dOff)
        //then we are in shadow so darken       
        v -= d - dOff; 
        
        col = hsv2rgb(float3(h,s,v));
           
	}
    
    //post proc
	//vertical gradient grey
    col *= 0.7 + (fragCoord.y/_STResolution.y *0.3);
    
    //add noise texture
    col += (0.0 - 0.5) * 0.05;
    
    return float4(col, 1.0);   
}

        ENDHLSL

        Pass
        {
            Name "ForwardUnlit"
            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex UnlitPassVertex
            #pragma fragment UnlitPassFragment
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #define SHADERTOY_RENDER_FUNCTION RenderNoiseHoles
            #include "../../Common/Shaders/ShadertoyURPForwardPass.hlsl"
            ENDHLSL
        }
    }
}