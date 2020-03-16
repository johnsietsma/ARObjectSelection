Shader "TESTUnlit/ARCoreBackground_ObjectSelection"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
    }

    // For GLES3
    SubShader
    {
        Pass
        {
            ZWrite Off
            Cull Off

            GLSLPROGRAM

#pragma only_renderers gles3

#ifdef SHADER_API_GLES3
#extension GL_OES_EGL_image_external_essl3 : require
#endif // SHADER_API_GLES3

            uniform mat4 _UnityDisplayTransform;

#ifdef VERTEX
            varying vec2 textureCoord;
            



            void main()
            {
#ifdef SHADER_API_GLES3
                float flippedV = 1.0 - gl_MultiTexCoord0.y;
                textureCoord.x = _UnityDisplayTransform[0].x * gl_MultiTexCoord0.x + _UnityDisplayTransform[1].x * flippedV + _UnityDisplayTransform[2].x;
                textureCoord.y = _UnityDisplayTransform[0].y * gl_MultiTexCoord0.x + _UnityDisplayTransform[1].y * flippedV + _UnityDisplayTransform[2].y;
                gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
#endif // SHADER_API_GLES3
            }
#endif // VERTEX

#ifdef FRAGMENT
            varying vec2 textureCoord;
            uniform samplerExternalOES _MainTex;

#if defined(SHADER_API_GLES3) && !defined(UNITY_COLORSPACE_GAMMA)
            float GammaToLinearSpaceExact (float value)
            {
                if (value <= 0.04045F)
                    return value / 12.92F;
                else if (value < 1.0F)
                    return pow((value + 0.055F)/1.055F, 2.4F);
                else
                    return pow(value, 2.2F);
            }

            vec3 GammaToLinearSpace (vec3 sRGB)
            {
                // Approximate version from http://chilliant.blogspot.com.au/2012/08/srgb-approximations-for-hlsl.html?m=1
                return sRGB * (sRGB * (sRGB * 0.305306011F + 0.682171111F) + 0.012522878F);

                // Precise version, useful for debugging, but the pow() function is too slow.
                // return vec3(GammaToLinearSpaceExact(sRGB.r), GammaToLinearSpaceExact(sRGB.g), GammaToLinearSpaceExact(sRGB.b));
            }
            
            float Epsilon = 1e-10;
 
vec3 RGBtoHCV(in vec3 RGB)
{
    // Based on work by Sam Hocevar and Emil Persson
    vec4 P = (RGB.g < RGB.b) ? vec4(RGB.bg, -1.0, 2.0/3.0) : vec4(RGB.gb, 0.0, -1.0/3.0);
    vec4 Q = (RGB.r < P.x) ? vec4(P.xyw, RGB.r) : vec4(RGB.r, P.yzx);
    float C = Q.x - min(Q.w, Q.y);
    float H = abs((Q.w - Q.y) / (6.0 * C + Epsilon) + Q.z);
    return vec3(H, C, Q.x);
}

vec3 RGBtoHSV(in vec3 rgb)
{
    // RGB [0..1] to Hue-Saturation-Value [0..1]
    vec3 hcv = RGBtoHCV(rgb);
    float s = hcv.y / (hcv.z + Epsilon);
    return vec3(hcv.x, s, hcv.z);
}

vec3 HUEtoRGB(in float H)
{
    float R = abs(H * 6.0 - 3.0) - 1.0;
    float G = 2.0 - abs(H * 6.0 - 2.0);
    float B = 2.0 - abs(H * 6.0 - 4.0);
    return clamp(vec3(R,G,B), 0.0, 1.0);
}

vec4 ColorAt(vec2 uv)
{
    vec3 col = texture(_MainTex, uv).xyz;
    float hue = RGBtoHSV(col).x;
    hue = float(int(hue*2.0))/2.0;
    return vec4(hue,hue,hue,1);// vec4(HUEtoRGB(hue),1);
}

void make_kernel(inout vec4 n[9], vec2 coord)
{
	float w = 1.0 / 1080.0;
	float h = 1.0 / 2160.0;

	n[0] = ColorAt(coord + vec2( -w, -h));
	n[1] = ColorAt(coord + vec2(0.0, -h));
	n[2] = ColorAt(coord + vec2(  w, -h));
	n[3] = ColorAt(coord + vec2( -w, 0.0));
	n[4] = ColorAt(coord);
	n[5] = ColorAt(coord + vec2(  w, 0.0));
	n[6] = ColorAt(coord + vec2( -w, h));
	n[7] = ColorAt(coord + vec2(0.0, h));
	n[8] = ColorAt(coord + vec2(  w, h));
}
#endif // SHADER_API_GLES3 && !UNITY_COLORSPACE_GAMMA


            void main()
            {
#ifdef SHADER_API_GLES3
                vec3 color = texture(_MainTex, textureCoord).xyz;

#ifndef UNITY_COLORSPACE_GAMMA
                color = GammaToLinearSpace(color);
#endif // !UNITY_COLORSPACE_GAMMA

                //float hue = RGBtoHCV(color).x;
                //hue = float(int(hue*2.0))/2.0;
                //color = HUEtoRGB(hue);
                
                vec4 n[9];
	make_kernel( n, textureCoord );

	vec4 sobel_edge_h = n[2] + (2.0*n[5]) + n[8] - (n[0] + (2.0*n[3]) + n[6]);
  	vec4 sobel_edge_v = n[0] + (2.0*n[1]) + n[2] - (n[6] + (2.0*n[7]) + n[8]);
	vec4 sobel = sqrt((sobel_edge_h * sobel_edge_h) + (sobel_edge_v * sobel_edge_v));
	

                gl_FragColor = vec4(color, 1) + vec4(sobel.rgb,1);
#endif // SHADER_API_GLES3
            }

#endif // FRAGMENT
            ENDGLSL
        }
    }

    FallBack Off
}
