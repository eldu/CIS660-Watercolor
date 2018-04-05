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

uniform vec4 gPaperColor
#if OGSFX
	<
    string Object = "Watercolor";
    string UIName = "Paper Color";
	string UIWidget = "Color";
> = {1.0, 1.0, 1.0, 1.0f};
#else
   = vec4(1.0, 1.0, 1.0, 1.0);
#endif

uniform vec4 gObjectColor
#if OGSFX
<
    string UIName = "Object Color";
	string UIWidget = "Color";
> = {1.0, 0.1, 0.1, 1.0f};
#else
   = vec4(1.0, 0.1, 0.1, 1.0);
#endif

uniform float ctrl_turb
#if OGSFX
<
    string UIWidget = "slider";
    float UIMin = 0.01;
    float UIMax = 1.0;
    float UIStep = 0.01;
    string UIName = "Turbulence";
>
#endif
	= 0.7;
    
uniform bool useTextureColor
<
	string UIName = "Use Texture Color?";
	int UIOrder = 20;
> = false;

uniform bool useTextureTurbulence
<
	string UIName = "Use Texture Turbulence?";
	int UIOrder = 20;
> = false;
	
// Defining textures is only necessary in OGSFX since it 
// can be assigned automatically to a sampler
#if OGSFX
uniform texture2D objectTexture <
    //string ResourceName = "test_texture.png";
    string ResourceType = "2D";
    // string UIWidget = "None";
    //string UIDesc = "Special Mipped Stripe";
    string UIName = "Object Texture";
>;
#endif

uniform sampler2D gObjectTextureSampler
#if OGSFX
	= sampler_state {
	Texture = <objectTexture>;
}
#endif
	;
    
#if OGSFX
uniform texture2D turbulenceTexture <
    string ResourceType = "2D";
    string UIName = "Turbulence Texture";
>;
#endif

uniform sampler2D gTurbulenceTextureSampler
#if OGSFX
	= sampler_state {
	Texture = <turbulenceTexture>;
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
    vec2 VSUV: TEXCOORD5;
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
in vec2 VSUV;

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

// Define constants
#define M_PI 3.14159265

// https://stackoverflow.com/questions/4200224/random-noise-functions-for-glsl
float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float noise_gen2(float x, float y, float z) {
    return fract(sin(dot(vec3(x, y, z), vec3(12.9898, 78.233, 43.29179))) * 43758.5453);
}

// Cosine Interpolation
float cerp (float a, float b, float x) {
    float y = x * M_PI;
    y = (1.0 - cos(y)) * 0.5; // y is inbetween[0, 1]
    return a * (1.0 - y) + b * y; // map y between a and b
}

float smoothNoise(float x, float y, float z) {
    float center = noise_gen2(x, y, z) / 8.0;
    float adj = (noise_gen2(x + 1., y, z) + noise_gen2(x - 1., y, z)
               + noise_gen2(x, y + 1., z) + noise_gen2(x, y - 1., z)
               + noise_gen2(x, y, z + 1.) + noise_gen2(z, y, z - 1.)) / 16.0;
    float diag = (noise_gen2(x + 1., y + 1., z)
                + noise_gen2(x + 1., y - 1., z)
                + noise_gen2(x - 1., y + 1., z)
                + noise_gen2(x - 1., y - 1., z)
                + noise_gen2(x + 1., y, z + 1.)
                + noise_gen2(x + 1., y, z - 1.)
                + noise_gen2(x - 1., y, z + 1.)
                + noise_gen2(x - 1., y, z - 1.)
                + noise_gen2(x, y + 1., z + 1.)
                + noise_gen2(x, y + 1., z - 1.)
                + noise_gen2(x, y - 1., z + 1.)
                + noise_gen2(x, y - 1., z - 1.)) / 32.0;
    float corners = (noise_gen2(x + 1., y + 1., z + 1.)
                    + noise_gen2(x + 1., y + 1., z - 1.) 
                    + noise_gen2(x + 1., y - 1., z + 1.) 
                    + noise_gen2(x + 1., y - 1., z - 1.) 
                    + noise_gen2(x - 1., y + 1., z + 1.) 
                    + noise_gen2(x - 1., y + 1., z - 1.) 
                    + noise_gen2(x - 1., y - 1., z + 1.) 
                    + noise_gen2(x - 1., y - 1., z - 1.)) / 64.0;
        
    return center + adj + diag + corners;
}

float interpSmoothNoise3D(float x, float y, float z) {
    // Get integer and fraction portions of x, y, z
    float intX = floor(x);
    float fractX = fract(x);
    float intY = floor(y);
    float fractY = fract(y);
    float intZ = floor(z);
    float fractZ = fract(z);


    //  Point of the cube
    float c000 = noise_gen2(intX,     intY,     intZ     );
    float c001 = noise_gen2(intX,     intY,     intZ + 1. );
    float c010 = noise_gen2(intX,     intY + 1., intZ     );
    float c011 = noise_gen2(intX,     intY + 1., intZ + 1. );
    float c100 = noise_gen2(intX + 1., intY,     intZ     );
    float c101 = noise_gen2(intX + 1., intY,     intZ + 1. );
    float c110 = noise_gen2(intX + 1., intY + 1., intZ     );
    float c111 = noise_gen2(intX + 1., intY + 1., intZ + 1. );

    // //  Point of the cube
    // float c000 = smoothNoise(intX,     intY,     intZ     );
    // float c001 = smoothNoise(intX,     intY,     intZ + 1. );
    // float c010 = smoothNoise(intX,     intY + 1., intZ     );
    // float c011 = smoothNoise(intX,     intY + 1., intZ + 1. );
    // float c100 = smoothNoise(intX + 1., intY,     intZ     );
    // float c101 = smoothNoise(intX + 1., intY,     intZ + 1. );
    // float c110 = smoothNoise(intX + 1., intY + 1., intZ     );
    // float c111 = smoothNoise(intX + 1., intY + 1., intZ + 1. );

    // Interpolate over X
    float c00 = cerp(c000, c100, fractX);
    float c01 = cerp(c001, c101, fractX);
    float c10 = cerp(c010, c110, fractX);
    float c11 = cerp(c011, c111, fractX);

    // Interpolate over Y
    float c0 = cerp(c00, c10, fractY);
    float c1 = cerp(c01, c11, fractY);

    // Interpolate over Z
    return cerp(c0, c1, fractZ);
}



float fbm3D(float x, float y, float z) {
    float total = 0.f;
    float persistance = 0.4f;
    int octaves = 4;

    for (int i = 0; i < octaves; i++) {
        float frequency = (i * i);
        float amplitude = pow(persistance, i);

        total += interpSmoothNoise3D(x * frequency, y * frequency, z * frequency) * amplitude;
    }

    return total;
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
    // For cangiante
    float d_a = 1.f;
    float c = 0.6f;
    float d = 0.4f;
    
    //****************************************************************
    
    vec4 objectColor;
    if (useTextureColor) {
        objectColor = texture2D(gObjectTextureSampler, VSUV).rgba;
    } else {
        objectColor = gObjectColor;
    }
    
    // Cangiante
    float Da = clamp(dot(WorldNormal, -LightDir), 0, 1) + (d_a - 1.f);
    Da = Da / d_a;
    vec3 Cc = objectColor.xyz + vec3(Da * c);
    vec3 Cd = (d * Da * (gPaperColor.xyz - Cc)) + Cc;
    
    //colorOut = vec4(Cd, 1);
    
    
    // Turbulence
    vec3 Ct;
    float turbulence;
    
    if (useTextureTurbulence) {
        turbulence = texture2D(gTurbulenceTextureSampler, VSUV).r;
    } else {
        turbulence = fbm3D(ObjPos[0], ObjPos[1], ObjPos[2]) * ctrl_turb;
    }

    if (turbulence < 0.5) {
        Ct[0] = pow(Cd[0], 3 - (4 * turbulence));
        Ct[1] = pow(Cd[1], 3 - (4 * turbulence));
        Ct[2] = pow(Cd[2], 3 - (4 * turbulence));
    } else {
        Ct = (turbulence - 0.5) * 2 * (gPaperColor.xyz - Cd) + Cd;
    }

    colorOut = vec4(Ct, 1.0);
    
    //colorOut = texture2D(gStripeSampler, VSUV).rgba;
}

#endif
