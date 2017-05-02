Shader "flowmap" {
    Properties {
        _Flowmap ("Flowmap", 2D) = "white" {}
        _FlowAmount ("FlowAmount", Float ) = 0.5
        _FlowSpeed ("FlowSpeed", Float ) = 1
        _Texture ("Texture", 2D) = "white" {}
        _Heightmap ("Heightmap", 2D) = "white" {}
        _Offset ("Offset", Float ) = 0.1
        _RippleStrength ("RippleStrength", Float ) = 2
        _WaterSplash ("WaterSplash", Color) = (1,1,1,1)
        _Color ("Color", Color) = (0.5,0.8,0.8,0.75)
        _Normal ("Normal", 2D) = "bump" {}
        _Specularity ("Specularity", Float ) = 0.8
        _Gloss ("Gloss", Float ) = 0.8
        _FresnelExponent ("FresnelExponent", Float ) = 0
        _FresnelStrength ("FresnelStrength", Float ) = 1
        [HideInInspector]_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
    }
    SubShader {
        Tags {
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }
        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_FORWARDBASE
            #include "UnityCG.cginc"
            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            #pragma only_renderers d3d9 d3d11 glcore gles 
            #pragma target 3.0
			
			
            uniform float4 _LightColor0;
            uniform float4 _TimeEditor;
            uniform sampler2D _Flowmap; uniform float4 _Flowmap_ST;
            uniform float _FlowAmount;
            uniform float _FlowSpeed;
            uniform sampler2D _Texture; uniform float4 _Texture_ST;
            uniform sampler2D _Heightmap; uniform float4 _Heightmap_ST;
            uniform float _Offset;
            uniform float _RippleStrength;
            uniform float4 _WaterSplash;
            uniform float4 _Color;
            uniform float _Specularity;
            uniform sampler2D _Normal; uniform float4 _Normal_ST;
            uniform float _Gloss;
            uniform float _FresnelExponent;
            uniform float _FresnelStrength;
			
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
                UNITY_FOG_COORDS(5)
            };
			
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
                o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                float3 lightColor = _LightColor0.rgb;
                o.pos = mul(UNITY_MATRIX_MVP, v.vertex );
                UNITY_TRANSFER_FOG(o,o.pos);
                return o;
            }
			
            float4 frag(VertexOutput i) : COLOR {
				//Sample 4 points orthogonal in texture based on offset distance
                float2 _Flowmap_color = tex2D(_Flowmap,TRANSFORM_TEX(i.uv0, _Flowmap)).rg * 2.0;
				
                float2 yOffset = float2(0.0,_Offset);
                float upSample = tex2D(_Heightmap,TRANSFORM_TEX(i.uv0+yOffset, _Heightmap)).r;
                float downSample = tex2D(_Heightmap,TRANSFORM_TEX(i.uv0-yOffset, _Heightmap)).r;
				
                float2 xOffset = float2(_Offset,0.0);
                float rightSample = tex2D(_Heightmap,TRANSFORM_TEX(i.uv0+xOffset, _Heightmap)).r;
                float leftSample = tex2D(_Heightmap,TRANSFORM_TEX(i.uv0-xOffset, _Heightmap)).r;
				
				//Take dot product to get flow direction relative to sides of a shape appearing in the depth buffer
                float dotDir = dot(float2(upSample - downSample,rightSample - leftSample) * _RippleStrength, _Flowmap_color);
				//only take negative values to get flow effect in one direction
				dotDir = abs(min(0,dotDir));
				
                //Get total flowmap offset somewhere between the original offset and the tangent direction, based on the dot itself (0 to 1)
				//Multiply by FlowAmount to give variable distance/distortion of flowmap
                float2 finalFlow = (lerp(_Flowmap_color, dotDir * _Flowmap_color, dotDir) * _FlowAmount * -1.0);
				
				//Flowmap function here using finalFlow colors
                float4 time4 = _Time + _TimeEditor;
				//Control of speed it takes flowmap to reset
                float time = (time4.r * _FlowSpeed);
				//Take remainder of time used to lerp between original uv and uv + flowmap uv offset
                time = frac(time);
				//Add uv to the flow offset to get the uv coordinate to sample and the farther uv sample
                float2 flowOffset = ((finalFlow * time)+ i.uv0);
				float2 flowOffset2 = ((finalFlow*frac((time+0.5)))+i.uv0);
				//Unity specific unpacking/shifting for normalmaps
                float3 normal = UnpackNormal(tex2D(_Normal,TRANSFORM_TEX(flowOffset, _Normal)));
				float3 normal2 = UnpackNormal(tex2D(_Normal,TRANSFORM_TEX(flowOffset2, _Normal)));
                //Get texture as well with same uv's
				float4 textureColor = tex2D(_Texture,TRANSFORM_TEX(flowOffset, _Texture));
                float4 textureColor2 = tex2D(_Texture,TRANSFORM_TEX(flowOffset2, _Texture));
				
				
                float timeLerp = abs(((0.5-time)/0.5));
				//Caclulate final normalmap to be used with the water shader, flowmap is complete
                float3 normalFinal = lerp(normal,normal2,timeLerp);
				float3 textureColorFinal = lerp(textureColor.rgb,textureColor2.rgb,timeLerp) * _Color.rgb;
				
				//Below is water shader things that use the normal map
				//This isn't directly tied to the flowmap, but highlights the use of the flowmap
				//There are many ways to do water effects and I just added various effects together
				
				//Stock variables to use later
				i.normalDir = normalize(i.normalDir);
                float3x3 tangentTransform = float3x3( i.tangentDir, i.bitangentDir, i.normalDir);
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                float3 normalDirection = normalize(mul( normalFinal, tangentTransform ));
                float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                float3 lightColor = _LightColor0.rgb;
                float3 halfDirection = normalize(viewDirection+lightDirection);

				//Gloss for specular
                float specPow = exp2( _Gloss * 10.0 + 1.0 );
				//specular
                float NdotL = saturate(dot( normalDirection, lightDirection ));
                float3 specularColor = float3(_Specularity,_Specularity,_Specularity);
                float3 directSpecular =  _LightColor0.xyz * pow(max(0,dot(halfDirection,normalDirection)),specPow)*specularColor;
                float3 specular = directSpecular;
				
				//Diffuse
                NdotL = max(0.0,dot( normalDirection, lightDirection ));
                float3 directDiffuse = max( 0.0, NdotL) *  _LightColor0.xyz;
                float3 indirectDiffuse = float3(0,0,0);
                indirectDiffuse += UNITY_LIGHTMODEL_AMBIENT.rgb; // Ambient Light
                
				//Add tint based on dot dir, add fresnel
                float3 diffuseColor = ((dotDir*_WaterSplash.rgb)+(textureColorFinal + ((_FresnelStrength*pow(1.0-max(0,dot(normalDirection, viewDirection)),_FresnelExponent)))));
                float3 diffuse = (directDiffuse + indirectDiffuse) * diffuseColor;
				
                float3 finalColor = diffuse + specular;
                fixed4 finalRGBA = fixed4(finalColor,_Color.a);
				
                return finalRGBA;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
