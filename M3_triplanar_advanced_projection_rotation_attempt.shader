// http://polycount.com/discussion/comment/1565050#Comment_1565050
// https://forum.unity3d.com/threads/rotating-the-world-normal-vector-in-surface-shader.173338/

Shader "MACHIN3/Triplanar/Advanced (Projection Rotation Attempt" {
	Properties {
		_Texture1 ("Texture 1", 2D) = "white" {}
        /*_Texture2 ("Texture 2", 2D) = "white" {}*/
        /*_Texture3 ("Texture 3", 2D) = "hite" {}*/
		_Scale ("Scale", Range(0.1, 100)) = 1

		_RotationX ("UV Rotation X", Range(-180, 180)) = 0
		_RotationY ("UV Rotation Y", Range(-180, 180)) = 0
		_RotationZ ("UV Rotation Z", Range(-180, 180)) = 0

		_XAngle ("Projection Rotation X", Range(-180, 180)) = 0

	}
	SubShader {
		Tags { "RenderType"="Opaque" }

        // TODO: try rotating the projection as well    
        // TODO: mix two metallic/smoothness grunge maps, each with a different scale?
		
		CGPROGRAM
		#pragma surface surf Standard vertex:vert
		#pragma target 3.0

		sampler2D _Texture1;
        /*sampler2D _Texture2;*/
        /*sampler2D _Texture3;*/
		float _Scale;
		float _RotationX;
		float _RotationY;
		float _RotationZ;
		float _XAngle;

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

            // Rotation Matrix
            float2x2 rotX = float2x2(cos(radians(_RotationX)), -sin(radians(_RotationX)), sin(radians(_RotationX)), cos(radians(_RotationX)));
            float2x2 rotY = float2x2(cos(radians(_RotationY)), -sin(radians(_RotationY)), sin(radians(_RotationY)), cos(radians(_RotationY)));
            float2x2 rotZ = float2x2(cos(radians(_RotationZ)), -sin(radians(_RotationZ)), sin(radians(_RotationZ)), cos(radians(_RotationZ)));

            // rotate and scale texture coordinates
            float2 coordYZ = mul(rotX, IN.localCoord.yz) * _Scale;
            float2 coordXZ = mul(rotY, IN.localCoord.xz) * _Scale;
            float2 coordXY = mul(rotZ, IN.localCoord.xy) * _Scale;

           
            float3 rotatedNormal;          
            float angle = radians(_XAngle);

            /*rotatedNormal.x = (IN.localNormal.x);*/
            /*rotatedNormal.y = (IN.localNormal.y * cos(Xangle) + IN.localNormal.y * -sin(Xangle));*/
            /*rotatedNormal.z = (+IN.localNormal.z * sin(Xangle) + IN.localNormal.z * cos(Xangle));  */
             

            float3x3 rotationMatrixX = {float3(1.0,0.0,0.0),
                                        float3(0.0,cos(angle),-sin(angle)),
                                        float3(0.0,sin(angle),cos(angle))};

            rotatedNormal = mul(IN.localNormal, rotationMatrixX);


            float3x3 rotationMatrixY = {float3(cos(angle),0.0,sin(angle)),
                                        float3(0.0,1.0,0.0),
                                        float3(-(angle),0.0,cos(angle))};

            rotatedNormal = mul(rotatedNormal, rotationMatrixY);

            float3x3 rotationMatrixZ = {float3(cos(angle),-sin(angle),0.0),
                                        float3(sin(angle),cos(angle),0.0),
                                        float3(0.0,0.0,1.0)};

            rotatedNormal = mul(rotatedNormal, rotationMatrixZ);

            // blend factor
            /*float3 bf = normalize(abs(IN.localNormal));*/
            float3 bf = normalize(abs(rotatedNormal));
            bf /= dot(bf, float3(1));

            // Color            
            fixed4 cx = tex2D(_Texture1, coordYZ) * bf.x;
            fixed4 cy = tex2D(_Texture1, coordXZ) * bf.y;
            fixed4 cz = tex2D(_Texture1, coordXY) * bf.z;
            fixed4 c  = cx + cy + cz;

            o.Albedo = c.rgb;
		}

		ENDCG
	}
	FallBack "Diffuse"
}
