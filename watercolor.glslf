#if !OGSFX
#version 330
#endif
/*********************************************************************NVMH3****
*******************************************************************************
$Revision: #1 $

This GLSL sample was converted from HLSL. Here are the original comments:

Copyright NVIDIA Corporation 2008
TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, THIS SOFTWARE IS PROVIDED
*AS IS* AND NVIDIA AND ITS SUPPLIERS DISCLAIM ALL WARRANTIES, EITHER EXPRESS
OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, IMPLIED WARRANTIES OF MERCHANTABILITY
AND FITNESS FOR A PARTICULAR PURPOSE.  appdata NO EVENT SHALL NVIDIA OR ITS SUPPLIERS
BE LIABLE FOR ANY SPECIAL, INCIDENTAL, INDIRECT, OR CONSEQUENTIAL DAMAGES
WHATSOEVER (INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOSS OF BUSINESS PROFITS,
BUSINESS INTERRUPTION, LOSS OF BUSINESS INFORMATION, OR ANY OTHER PECUNIARY
LOSS) ARISING OUT OF THE USE OF OR INABILITY TO USE THIS SOFTWARE, EVEN IF
NVIDIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

% Brick pattern, with controls, using texture-based patterning.
% The lighting here is PURELY lambert and from a directional source,
% 	so it's done in the vertex shader.

keywords: material pattern virtual_machine

$Date: 2008/07/21 $

keywords: OpenGL

To learn more about shading, shaders, and to bounce ideas off other shader
    authors and users, visit the NVIDIA Shader Library Forums at:

    http://developer.nvidia.com/forums/

*******************************************************************************
******************************************************************************/

/*****************************************************************/
/*** EFFECT-SPECIFIC CODE BEGINS HERE ****************************/
/*****************************************************************/

//**********
//	Uniform parameter handling:
//
//	The OGSFX specifications provides support for annotations and
//	semantics which are missing in the GLSL specifications. This
//	means that we need to cut out all unsupported information if we are
//	using this shader in raw GLSL mode. This makes the code quite
//	heavy, but insures that uniforms are defined in a single location.
//	
//	For another lighter (but more error prone) approach to uniform
//	parameter handling you can look into the Brix.glslv file.
//

#if !HIDE_OGSFX_UNIFORMS

uniform vec4 gSurfColor1
#if OGSFX
	<
    string UIName = "Brick 1";
	string UIWidget = "Color";
> = {0.9, 0.5, 0.0, 1.0f};
#else
   = vec4(0.9, 0.5, 0.0, 1.0);
#endif

uniform vec4 gSurfColor2
#if OGSFX
<
    string UIName = "Brick 2";
	string UIWidget = "Color";
> = {0.8, 0.48, 0.15, 1.0f};
#else
   = vec4(0.8, 0.48, 0.15, 1.0f);
#endif

uniform vec4 gGroutColor
#if OGSFX
<
    string UIName = "Grouting";
	string UIWidget = "Color";
> = {0.8f, 0.75f, 0.75f, 1.0f};
#else
   = vec4(0.7,-0.7,-0.7, 1.0);
#endif

uniform float gGBalance
#if OGSFX
<
    string UIWidget = "slider";
    float UIMin = 0.01;
    float UIMax = 0.35;
    float UIStep = 0.01;
    string UIName = "Grout::Brick Ratio";
>
#endif
	= 0.1;
	
// Defining textures is only necessary in OGSFX since it 
// can be assigned automatically to a sampler
#if OGSFX
uniform texture2D gStripeTexture <
    string ResourceName = "aa_stripe.dds";
    string ResourceType = "2D";
    // string UIWidget = "None";
    string UIDesc = "Special Mipped Stripe";
>;
#endif

uniform sampler2D gStripeSampler
#if OGSFX
	= sampler_state {
	Texture = <gStripeTexture>;
}
#endif
	;

#endif

//**********
//	Input stream handling:
//
//	The OGSFX specifications provides support for semantics which is
//	missing in the GLSL specifications. The syntax is sufficiently 
//	different that it becomes easier to simply have two sections
//	for OGSFX and GLSL
//

#if !HIDE_OGSFX_STREAMS
#if OGSFX

/************* DATA STRUCTS **************/

/* data passed from vertex shader to pixel shader */
attribute brixPixelInput {
    vec3 WorldNormal    : TEXCOORD1;
    vec3 WorldEyeVec    : TEXCOORD2;
    vec4 ObjPos    : TEXCOORD3;
    vec4 DCol : COLOR0;
    vec3 LightDir : TEXCOORD4;
};

/* data output by the fragment shader */
attribute pixelOut 
{
    vec4 colorOut:COLOR0;
}

#else

in vec3 WorldNormal;
in vec3 WorldEyeVec;
in vec4 ObjPos;
in vec4 DCol;
in vec3 LightDir;

out vec4 colorOut;

#endif
#endif

//**********
//	Code handling:
//
//	The OGSFX specifications requires code blocks to be defined
//	inside GLSLShader sections. This is handled by the master
//	Brix.ogsfx file, but could also be added here protected between
//	#if OGSFX preprocessor directives.
//

#if !HIDE_OGSFX_CODE

// https://stackoverflow.com/questions/4200224/random-noise-functions-for-glsl
float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

// Copied from 560 slides
float interpNoise2D(float x, float y) {
    float intX = floor(x);
    float fractX = fract(x);
    float intY = floor(y);
    float fractY = fract(y);
    
    float v1 = rand(vec2(intX, intY));
    float v2 = rand(vec2(intX + 1, intY));
    float v3 = rand(vec2(intX, intY + 1));
    float v4 = rand(vec2(intX + 1, intY + 1));
    
    float i1 = mix(v1, v2, fractX);
    float i2 = mix(v3, v4, fractX);
    return mix(i1, i2, fractY);
}

float fbm(float x, float y) {
   float total = 0;
   float persistance = 0.5f;
   int octaves = 4;
   
   for (int i = 0; i < octaves; i++) {
       float freq = pow(2.f, i);
       float amp = pow(persistance, i);
       
       total += interpNoise2D(x * freq, y * freq) * amp;
   }
   return total;
}

void main()
{
    // TODO
    // how to get the object's base color?
    vec3 objColor = vec3(1, 0.1, 0.1);

    // Variables that need to be change for art direction ************
    vec3 paperColor = vec3(1, 1, 1);
    
    // For cangiante
    float d_a = 1.f;
    float c = 0.6f;
    float d = 0.4f;
    
    // For turbulence
    float ctrl_turb = 0.1;
    
    //****************************************************************
    
    // Cangiante
    float Da = clamp(dot(WorldNormal, -LightDir), 0, 1) + (d_a - 1.f);
    Da = Da / d_a;
    vec3 Cc = objColor + vec3(Da * c);
    vec3 Cd = (d * Da * (paperColor - Cc)) + Cc;
    
    //colorOut = vec4(Cd, 1);
    
    
    // Turbulence
    vec3 Ct;
    ctrl_turb = fbm(ObjPos[0], ObjPos[1]) * 0.3f;

    if (ctrl_turb < 0.5) {
        Ct[0] = pow(Cd[0], 3 - (4 * ctrl_turb));
        Ct[1] = pow(Cd[1], 3 - (4 * ctrl_turb));
        Ct[2] = pow(Cd[2], 3 - (4 * ctrl_turb));
    } else {
        Ct = (ctrl_turb - 0.5) * 2 * (paperColor - Cd) + Cd;
    }

    colorOut = vec4(Ct, 1);
    
    //colorOut = vec4(ctrl_turb, ctrl_turb, ctrl_turb, 1);
    
    //vec3 normalColor = (WorldNormal + vec3(1)) / 2.0;
    //colorOut = vec4(normalColor, 1);
}

#endif
