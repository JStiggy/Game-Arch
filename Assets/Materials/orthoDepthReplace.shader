Shader "testUnlit" {
    Properties {
        _Offset ("Offset", Float ) = 1
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
			
            struct VertexInput {
                float4 vertex : POSITION;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float4 projPos : TEXCOORD0;
            };
			
            VertexOutput vert (VertexInput v) {
				//Standard voutput
                VertexOutput o = (VertexOutput)0;
                o.pos = mul(UNITY_MATRIX_MVP, v.vertex );
				
				//Only camera projection is actually important for sampling in frag shader
				//For rendertexture/depth uv's in frag
                o.projPos = ComputeScreenPos (o.pos);
                COMPUTE_EYEDEPTH(o.projPos.z);
                return o;
            }
			
            float4 frag(VertexOutput i) : COLOR {
				//Sample camera depth texture and place in red channel
                float sceneZ = UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)));
				//saturate clamps between 0 and 1
                return float4(saturate(sceneZ*_Offset), 0.0, 0.0, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
