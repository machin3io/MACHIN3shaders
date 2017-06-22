// http://www.shaderslab.com/index.php?post/Triplanar-mapping

Shader "MACHIN3/Triplanar/Simple" {
	Properties {
        _Tint ("Tint", Color) = (1,1,1,1)
        _TintAmount ("Tint Amount", Range(0, 1)) = 0.5
		_Albedo ("Albedo", 2D) = "white" {}
		_Metallic ("Metallic(RGB), Smoothness(A)", 2D) = "black" {}
		_Scale ("Scale", Range(0.1, 100)) = 1
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		
		CGPROGRAM
		#pragma surface surf Standard vertex:vert
		#pragma target 3.0

		float4 _Tint;
		float _TintAmount;
		sampler2D _Albedo;
		sampler2D _Metallic;
		float _Scale;

		struct Input {
            float3 localCoord;
            float3 localNormal;
		};

        void vert(inout appdata_full v, out Input data)
        {
            UNITY_INITIALIZE_OUTPUT(Input, data);
            data.localCoord = v.vertex.xyz;
            data.localNormal = v.normal.xyz;
        }

		void surf (Input IN, inout SurfaceOutputStandard o) {

            // scale texture coordinates
            float2 tx = IN.localCoord.yz * _Scale;
            float2 ty = IN.localCoord.xz * _Scale;
            float2 tz = IN.localCoord.xy * _Scale;
 
            // blend factor
            float3 bf = normalize(abs(IN.localNormal));
            bf /= dot(bf, float3(1));

            // Color            
            fixed4 cx = tex2D(_Albedo, tx) * bf.x;
            fixed4 cy = tex2D(_Albedo, ty) * bf.y;
            fixed4 cz = tex2D(_Albedo, tz) * bf.z;
            fixed3 c  = cx + cy + cz;

            // Metallic
            fixed4 mx = tex2D(_Metallic, tx) * bf.x;
            fixed4 my = tex2D(_Metallic, ty) * bf.y;
            fixed4 mz = tex2D(_Metallic, tz) * bf.z;
            fixed4 m  = mx + my + mz;

            o.Albedo = lerp(c, _Tint, _TintAmount);
            o.Metallic = m.rgb;
            o.Smoothness = m.a;
		}

		ENDCG
	}
	FallBack "Diffuse"
}
