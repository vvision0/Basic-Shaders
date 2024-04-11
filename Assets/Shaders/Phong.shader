Shader "Unlit/Phong"
{
    Properties
    {
        // 添加这个变量是因为光照颜色会影响高光颜色
        _BaseColor ("BaseColor", Color) = (1.0, 1.0, 1.0, 1.0)
        // 控制高光的聚集程度，数值越高，高光越聚集
        _SpecularIntensity ("SpecularIntensity", Range(8, 20)) = 8.0
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
            "RenderPipeline"="UniversalRenderPipeline"
        }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            // 所有在Properties中声明并且用在着色器中的变量需要放在这里
            // 因此如果在Properties中声明了_MainTex但并没有用在函数中，就不用放在这里
            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                half _SpecularIntensity;
            CBUFFER_END
            
            // 因为不存在纹理采样，所以不需要纹理采样函数
            // TEXTURE2D(_MainTex);
            // SAMPLER(sampler_MainTex);

            // 预处理命令的执行不受顺序影响，因此可以放在include下面
            #pragma vertex vert
            #pragma fragment frag

            struct Attributes
            {
                // 需要这个变量的原因是高光会随着摄像机变化而变化，因此需要知道顶点位置从而适应摄像机移动
                float4 positionObjectSpace : POSITION;
                // 计算高光必须的变量
                float3 normal              : NORMAL;
            };

            struct Varyings
            {
                float4 positionClipSpace   : SV_POSITION;
                float3 normalWorldSpace    : TEXCOORD0;
                // 需要这个变量的原因是用来计算摄像机观察方向
                float3 positionWorldSpace  : TEXCOORD1;
            };


            Varyings vert(Attributes vertexInput)
            {
                Varyings vertexOutput;
                // 参数需要带.xyz
                vertexOutput.positionClipSpace = TransformObjectToHClip(vertexInput.positionObjectSpace.xyz);
                vertexOutput.normalWorldSpace = TransformObjectToWorldNormal(vertexInput.normal);
                vertexOutput.positionWorldSpace = TransformObjectToWorld(vertexInput.positionObjectSpace.xyz);
                return vertexOutput;
            }

            half4 frag(Varyings fragmentInput) : SV_TARGET
            {
                Light light = GetMainLight();
                half3 lightDirection = SafeNormalize(light.direction);
                // 片元的位置减去摄像机的位置，代表从摄像机看向该片元的方向
                half3 viewDirection = SafeNormalize(_WorldSpaceCameraPos.xyz - fragmentInput.positionWorldSpace);

                // Phong
                half3 reflectDirection = SafeNormalize(reflect(lightDirection, fragmentInput.normalWorldSpace));
                float specularGray = pow(saturate(dot(viewDirection, -reflectDirection)), _SpecularIntensity);
                
                // 叠加光照颜色
                half3 specularRGB = _BaseColor.xyz * specularGray;
                return half4(specularRGB, 1);
            }
            ENDHLSL
        }
    }
}
