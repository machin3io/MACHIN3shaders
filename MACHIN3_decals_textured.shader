﻿Shader "MACHIN3/Decals/Textured" 
{
	Properties 
	{
        _AoCurvHeightSubset ("Ambient Occlusion(R), Curvature(B), Height(B), Subset Mask(A)", 2D) = "white" {}
		_NormalAlpha ("Normal(RGB) Decal Mask(A)", 2D) = "bump" {}

		_SubSetColorMap ("Albedo(RGB)", 2D) = "white" {}
		_MetalnessMap ("Metallic(RGB), Smoothness(A), ", 2D) = "white" {}

		_ParallaxHeight ("Parallax height", Range (0.0, 0.2)) = 0.07
		_AOStrength ("AO Strength", Range (0.0, 4)) = 1

		_SimpleWear ("Simple Wear", Range(0,4)) = 0
		_SimpleWearColor ("Simple Wear Color", Color) = (0.8, 0.8, 0.8)
		_SimpleWearMetalness ("Simple Wear Metallic", Range(0,1)) = 1.0
		_SimpleWearSmoothness ("Simple Wear Smoothness", Range(0,1)) = 0.63

        _Offset ("Offset", Range(-20, -1)) = -3
	}
	SubShader 
	{

        Tags {"Queue"="AlphaTest+2" "IgnoreProjector"="True" "RenderType"="Opaque" "ForceNoShadowCasting"="True"}
		LOD 300
		Offset [_Offset], [_Offset]

        Blend SrcAlpha OneMinusSrcAlpha, Zero OneMinusSrcAlpha

		CGPROGRAM

        #pragma surface surf Standard finalgbuffer:DecalFinalGBuffer exclude_path:forward exclude_path:prepass noshadow noforwardadd keepalpha
		#pragma target 3.0

        #include "MACHIN3.cginc"

		sampler2D _NormalAlpha;
		sampler2D _AoCurvHeightSubset;

		sampler2D _SubSetColorMap;
		sampler2D _MetalnessMap;

		float _ParallaxHeight;
        half _AOStrength;
		half _SimpleWear;
        float3 _SimpleWearColor;
		half _SimpleWearMetalness;

		struct Input 
		{
			float2 uv_AoCurvHeightSubset;
			float3 viewDir;
		};

		void surf (Input IN, inout SurfaceOutputStandard o) 
		{
            half h = LinearToGammaSpace(tex2D(_AoCurvHeightSubset, IN.uv_AoCurvHeightSubset).b); // a height map sampled from a non-alpha channel will be in the wrong color space, odd 
			float2 offset = ParallaxOffset (h, _ParallaxHeight, IN.viewDir);
			IN.uv_AoCurvHeightSubset += offset;

            fixed4 aocurvheightsubset = tex2D(_AoCurvHeightSubset, IN.uv_AoCurvHeightSubset);
            fixed3 normal = UnpackTextureNormal(tex2D(_NormalAlpha, IN.uv_AoCurvHeightSubset));

            fixed4 subsetColor = tex2D (_SubSetColorMap, IN.uv_AoCurvHeightSubset);
            fixed4 metalness = tex2D (_MetalnessMap, IN.uv_AoCurvHeightSubset);

            o.Occlusion = pow(LinearToGammaSpace(aocurvheightsubset.r), _AOStrength);

            o.Alpha = aocurvheightsubset.a + (1 - o.Occlusion); // this extends the subset alpha map by the range of the ao, important for decals without subsets, so they can receive ao
            o.Albedo = lerp(lerp(0, subsetColor.rgb, aocurvheightsubset.a), _SimpleWearColor, GammaToLinearSpace(aocurvheightsubset.g) * _SimpleWear) * o.Occlusion;  // the inner lerp makes the albedo outside the subset mask black, instead of the subset color. black because its the color of AO. The outer lerp is for the SimpleWearColor
            o.Metallic = lerp(metalness.rgb, _SimpleWearMetalness, GammaToLinearSpace(aocurvheightsubset.g) * _SimpleWear) * o.Occlusion; // lerping SimpleWearMetalness as well as ensuring theres AO on metal, or rather no metal where ao is.
			o.Normal = normal;
		}

        void DecalFinalGBuffer (Input IN, SurfaceOutputStandard o, inout half4 diffuse, inout half4 specSmoothness, inout half4 normal, inout half4 emission)
        {
			fixed decalalpha = tex2D (_NormalAlpha, IN.uv_AoCurvHeightSubset).a;

            diffuse.a = o.Alpha;
            specSmoothness.a = o.Alpha;
            normal.a = decalalpha; 
            emission.a = o.Alpha;
        }

        ENDCG

        // for some reason the blending above kills the specular
        // this second shader adds it

        Blend One One
        ColorMask A

        CGPROGRAM

        #pragma surface surf Standard finalgbuffer:DecalFinalGBuffer exclude_path:forward exclude_path:prepass noshadow noforwardadd keepalpha
        #pragma target 3.0

        #include "MACHIN3.cginc"

        sampler2D _NormalAlpha;
        sampler2D _AoCurvHeightSubset;

        sampler2D _BumpMap;
        sampler2D _MetalnessMap;

        float _ParallaxHeight;
        half _SimpleWear;
        half _SimpleWearSmoothness;

        struct Input 
        {
            float2 uv_AoCurvHeightSubset; 
            float3 viewDir;
        };

        void surf (Input IN, inout SurfaceOutputStandard o) 
        {
            half h = LinearToGammaSpace(tex2D (_AoCurvHeightSubset, IN.uv_AoCurvHeightSubset).b); // a height map sampled from a non-alpha channel will be in the wrong color space, odd 
            float2 offset = ParallaxOffset (h, _ParallaxHeight, IN.viewDir);
            IN.uv_AoCurvHeightSubset += offset;

            fixed4 aocurvheightsubset = tex2D (_AoCurvHeightSubset, IN.uv_AoCurvHeightSubset);
            fixed3 normal = UnpackTextureNormal(tex2D(_NormalAlpha, IN.uv_AoCurvHeightSubset));
            fixed4 metalness = tex2D (_MetalnessMap, IN.uv_AoCurvHeightSubset);

            o.Alpha = aocurvheightsubset.a;
            o.Normal = normal;
            o.Smoothness = lerp(metalness.a, _SimpleWearSmoothness, GammaToLinearSpace(aocurvheightsubset.g) * _SimpleWear); // lerping SimpleWearSmoothness

        }

        void DecalFinalGBuffer (Input IN, SurfaceOutputStandard o, inout half4 diffuse, inout half4 specSmoothness, inout half4 normal, inout half4 emission)
        {
            specSmoothness.a = o.Alpha * o.Smoothness;  // no idea, why the multiplication is necessary, but it works
        }

        ENDCG
	} 
	FallBack "Diffuse"
}
