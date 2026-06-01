/**
 * ------------------------------------------------------------------------
 * - Subsurface Scattering Demo
 * - Created by Steven Sell (ssell) / 2017
 * - License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
 * - https://www.shadertoy.com/view/4tlcWj
 * ------------------------------------------------------------------------
 *
 * Demo of subsurface scattering and local thickness, based on:
 *
 *     'Approximating Translucency for a Fast, Cheap and Convincing Subsurface Scattering Look'
 *      - Colin Barré-Brisebois and Marc Bouchard
 *      https://www.gdcvault.com/play/1014538/Approximating-Translucency-for-a-Fast
 * 
 * A very simple approach to approximating subsurface scattering/partial translucency.
 * It consists of primarily two steps:
 *
 *     (1) Calculate local thickness for the surface position.
 *     (2) Calculate the SSS lighting based on the local thickness and other properties.
 *
 * In order to do (1), simply calculate ambient occlusion but on the reversed normals.
 * So in essence you calculate AO for the inside of the object. In this demo, the 
 * thickness/inverted AO value is calculated by performing a random hemispherical sample
 * of SDF values along the inverted normal. See 'CalculateThickness' in Buf B. In the
 * source, their thickness values are baked into a texture and then sampled at runtime.
 *
 * The algorithm for (2) is explained neatly in the primary source linked above and is
 * implemented in 'Render' in Buf C.
 *
 * ------------------------------------------------------------------------
 * - Controls
 * ------------------------------------------------------------------------
 *
 * -- SSS [Enabled/Disabled]
 *
 *     Enables and disables SSS on the scene. Without SSS, standard direct
 *     illumination is used.
 *
 * -- Sample Count [1, 64]
 *
 *     Number of samples to perform when calculating the local thickness values.
 *
 * -- Sample Depth [0.01, 2.0]  <Back and Front Transluceny>
 *
 *     The maximum length of the random hemispherical sampling vector into the object.
 *     Naturally, the smaller this maximum value is the denser the object will be.
 *
 * -- Ambient [0.01, 1.0]       <Back and Front Transluceny>
 *
 *     Controls front and back translucency which is always present. Represents
 *     a minimum value for how much light is let through irregardless of whether
 *     the surface is in front (back translucency) or behind (front transluceny)
 *     the light source.
 *
 * -- Distortion [0.01, 2.0]    <Back Translucency>
 *
 *     Distorts the normal. Can be thought of the way the light bends around the
 *     surface, particularly at higher distortion values.
 *
 * -- Power [0.01, 2.0]         <Back Translucency>
 *
 *     Controls local power of scattering when in proximity to the light source.
 *
 * -- Scale [0.01, 5.0]         <Back Translucency>
 *
 *     Controls how much light goes through the back translucency. Higher value
 *     results in more light.
 *
 * -- Light Color
 *
 *     No idea what this does.
 *
 * ------------------------------------------------------------------------
 * - Buffers
 * ------------------------------------------------------------------------
 *
 *     Buf A: UI Logic and Rendering
 *     Buf B: Scene marching and G-Buffer
 *     Buf C: Scene rendering and shading
 *     Image: Scene + UI, Vignette, Gamma Correction
 *
 * ------------------------------------------------------------------------
 * - References / Sources
 * ------------------------------------------------------------------------
 *
 * [UI]
 *
 *     'UI easy to integrate' - XT95
 *     https://www.shadertoy.com/view/ldKSDm
 *
 * [SDF Shape and Normal Compression]
 *
 *     'Normals Compression - Octahedron' - iq
 *     https://www.shadertoy.com/view/Mtfyzl
 *
 * [Hash Functions]
 *
 *     'Hash without Sine' - Dave_Hoskins
 *     https://www.shadertoy.com/view/4djSRW
 */

//------------------------------------------------------------------------------------------
// UI Functions
//------------------------------------------------------------------------------------------

vec4 RenderSliders(in vec2 uv)
{
    return texture(iChannel1, uv);
}

//------------------------------------------------------------------------------------------
// Main
//------------------------------------------------------------------------------------------

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 ui = RenderSliders(uv);
    
	fragColor      = texture(iChannel0, uv);
    fragColor.rgb  = pow(fragColor.rgb, vec3(1.0 / 2.2));                                       // Gamma
    fragColor.rgb *= 0.4 + (0.6 * pow(32.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y), 0.2));  // Vignette
    fragColor.rgb  = mix(fragColor.rgb, ui.rgb, ui.a);                                          // UI mixing
}
