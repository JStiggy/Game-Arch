Shader "testUnlit" {
    Properties {
        _Offset ("Offset", Float ) = 1
        _Previous ("Previous", 2D) = "white" {}
    }
    SubShader {
        Tags {
            "Queue"="Overlay"
            "RenderType"="Opaque"
        }
        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }
            ZTest Always
            ZWrite Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_FORWARDBASE
            #include "UnityCG.cginc"
            #pragma target 3.0
			
            uniform sampler2D _CameraDepthTexture;
            uniform float _Offset;
            uniform sampler2D _Previous;
			uniform float4 _Previous_ST; //ST is for changing unity scale/offset of texture
			
            struct VertexInput {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 projPos : TEXCOORD1;
            };
            VertexOutput vert (VertexInput v) {
				//Standard voutput
                VertexOutput o = (VertexOutput)0;
                o.pos = mul(UNITY_MATRIX_MVP, v.vertex );
				
				//For rendertexture/depth uv's in frag
				o.uv0 = v.texcoord0;
                o.projPos = ComputeScreenPos (o.pos);
                COMPUTE_EYEDEPTH(o.projPos.z);
                return o;
            }
            float4 frag(VertexOutput i) : COLOR {
				//Sample camera depth texture and place in red channel
                float sceneZ = UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)));
				
				//Sample previous color from last frame and take the maximum value to maintain the heightmap
                float4 _Previous_color = tex2D(_Previous,TRANSFORM_TEX(i.uv0, _Previous));
				
                return float4(max(_Previous_color.rgb,saturate(sceneZ*_Offset)),1.0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
