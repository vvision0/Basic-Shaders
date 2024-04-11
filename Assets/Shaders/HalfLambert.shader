Shader "Unlit/HalfLambert"
{
    Properties
    {
        // 需要添加纹理时，就需要这个变量
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            // 先确定要执行哪些函数
            #pragma vertex vert
            #pragma fragment frag

            // 再导入库
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            // 顶点着色器输入
            struct Attributes
            {
                // 必须要顶点位置信息，原因是阴影效果会随着摄像机的移动而变化
                float4 positionObjectSpace : POSITION;
                // 物体空间的法线信息
                float3 normalObjectSpace   : NORMAL;
                // 必须要UV信息
                float2 uv                  : TEXCOORD0;
            };

            struct Varyings
            {
                // 必须要连接到SV_POSITION，代表裁剪空间的顶点位置信息
                float4 positionClipSpace : SV_POSITION;
                // 世界空间的法线信息
                float3 normalWorldSpace : TEXCOORD1;
                // UV信息不变
                float2 uv : TEXCOORD0;
                
            };

            // 必须包含，很容易漏掉
            // _XXX_ST的意思就是tiling和offset，这里指_MainTex的tiling和offset
            // _XXX_ST.xy对应tiling，_XXX_ST.zw对应offset
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
            CBUFFER_END

            // 必须包含，很容易漏掉
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            Varyings vert(Attributes vertInput)
            {
                // 用来输出
                Varyings vertOutput;
                //将顶点坐标从物体空间转换到裁剪空间
                vertOutput.positionClipSpace = TransformObjectToHClip(vertInput.positionObjectSpace.xyz);
                // 将法线坐标从物体空间转换到世界空间
                vertOutput.normalWorldSpace = TransformObjectToWorldNormal(vertInput.normalObjectSpace.xyz, true);
                // 将模型顶点的uv和tiling、offset两个变量进行运算，计算出实际显示用的顶点uv
                vertOutput.uv = TRANSFORM_TEX(vertInput.uv, _MainTex);
                // 把顶点着色器的输出送入片元着色器的输入
                return vertOutput;
            }
            
            half4 frag(Varyings fragInput) : SV_TARGET
            {
                // 获得光照信息
                Light light = GetMainLight();

                // 获得光照方向，注意这里光照方向并不是照过来的方向，而是光照过来的反方向
                half3 lightDirection = SafeNormalize(light.direction);
                // 将法线方向和光照方向点积
                half normalDotLight = dot(fragInput.normalWorldSpace, lightDirection);
                // 映射到[0,1]
                half halfLambert = normalDotLight * 0.5 + 0.5;

                // 光照颜色，real4是指自动转换为half4或者float4
                real4 lightColor = real4(light.color, 1);

                // 纹理颜色
                half4 textureColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, fragInput.uv);

                // 返回阴影、光照颜色、纹理颜色混合后的颜色
                return halfLambert * lightColor * textureColor;
            }
            ENDHLSL
        }
    }
}
