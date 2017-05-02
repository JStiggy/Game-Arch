Shader "snowShader" {
    Properties {
        _Color ("Color", Color) = (1,1,1,1)
        _Scale ("Scale", Float ) = -1
        _SnowColor ("SnowColor", Float ) = 1
        _Heightmap ("Heightmap", 2D) = "white" {}
        _PDDistanceCheck ("PD Distance Check", Range(0, 0.1)) = 0.01645206
        _NormalStrength ("Normal Strength", Float ) = 1
    }
    SubShader {
        Tags {
            "RenderType"="Opaque"
        }
        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }
            
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_FORWARDBASE
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #pragma multi_compile_fwdbase_fullshadows
            #pragma multi_compile_fog
            #pragma target 3.0
			
            uniform float4 _LightColor0;
            uniform float4 _Color;
            uniform float _Scale;
            uniform sampler2D _Heightmap; uniform float4 _Heightmap_ST;
            uniform float _PDDistanceCheck;
            uniform float _NormalStrength;
			
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 posWorld : TEXCOORD1;
                float3 normalDir : TEXCOORD2;
                float3 tangentDir : TEXCOORD3;
                float3 bitangentDir : TEXCOORD4;
                LIGHTING_COORDS(5,6)
                UNITY_FOG_COORDS(7)
            };
			
			
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
                o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
				
				//Use heightmap to offset vertex
                float4 height = tex2Dlod(_Heightmap,float4(TRANSFORM_TEX(o.uv0, _Heightmap),0.0,0));
                v.vertex.xyz += float3(float2(0.0,(height.r*_Scale)),0.0);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				
                float3 lightColor = _LightColor0.rgb;
                o.pos = mul(UNITY_MATRIX_MVP, v.vertex );
                UNITY_TRANSFER_FOG(o,o.pos);
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }
            float4 frag(VertexOutput i) : COLOR {
				
                
				//Normal recalculation
                float2 xUv = (i.uv0-float2(_PDDistanceCheck,0.0));
                float4 xSample = tex2D(_Heightmap,TRANSFORM_TEX(xUv, _Heightmap));
                float2 yUv = (i.uv0-float2(0.0,_PDDistanceCheck));
                float4 ySample = tex2D(_Heightmap,TRANSFORM_TEX(yUv, _Heightmap));
                float4 sample = tex2D(_Heightmap,TRANSFORM_TEX(i.uv0, _Heightmap));
                float2 newNormal = clamp(((float2(xSample.r,ySample.g)-sample.r)*_NormalStrength),-1,1);
                float3 normalLocal = float3(newNormal,sqrt((1.0 - dot(newNormal,newNormal))));
				
				//Stock variables to use later
				i.normalDir = normalize(i.normalDir);
                float3x3 tangentTransform = float3x3( i.tangentDir, i.bitangentDir, i.normalDir);
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                float3 normalDirection = normalize(mul( normalLocal, tangentTransform ));
                float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                float3 lightColor = _LightColor0.rgb;
                float3 halfDirection = normalize(viewDirection+lightDirection);
				
				//Lighting diffuse/attenuation
                float attenuation = LIGHT_ATTENUATION(i);
                float3 attenColor = attenuation * _LightColor0.xyz;

				//diffuse
                float NdotL = max(0.0,dot( normalDirection, lightDirection ));
                float3 diffuse = (max( 0.0, NdotL) * attenColor + UNITY_LIGHTMODEL_AMBIENT.rgb) * _Color.rgb;

                return fixed4(diffuse,1);
            }
            ENDCG
        }
        
        Pass {
			//Shadow pass has to also be redone because of the heightmap changing the geometry
			//Pretty much the same but only with vertex changes
            Name "ShadowCaster"
            Tags {
                "LightMode"="ShadowCaster"
            }
            Offset 1, 1
            Cull Back
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_SHADOWCASTER
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #pragma multi_compile_shadowcaster
            #pragma target 3.0
			
            uniform float _Scale;
            uniform sampler2D _Heightmap; uniform float4 _Heightmap_ST;
            struct VertexInput {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                V2F_SHADOW_CASTER;
                float2 uv0 : TEXCOORD1;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
				
				//Use heightmap to offset vertex
                float4 height = tex2Dlod(_Heightmap,float4(TRANSFORM_TEX(o.uv0, _Heightmap),0.0,0));
                v.vertex.xyz += float3(float2(0.0,(height.r*_Scale)),0.0);
				
                o.pos = mul(UNITY_MATRIX_MVP, v.vertex );
                TRANSFER_SHADOW_CASTER(o)
                return o;
            }
            float4 frag(VertexOutput i) : COLOR {
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
