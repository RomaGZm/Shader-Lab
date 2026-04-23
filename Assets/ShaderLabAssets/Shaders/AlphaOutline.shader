Shader "UI/SDFOutlineFire"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        _Color ("Base Color", Color) = (1,1,1,1)

        _OutlineColor ("Outline Color", Color) = (1,0.4,0,1)
        _OutlineWidth ("Outline Width", Float) = 0.02
        _Softness ("Softness", Float) = 0.01

        _FireSpeed ("Fire Speed", Float) = 2
        _NoiseScale ("Noise Scale", Float) = 8
        _Intensity ("Intensity", Float) = 2
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "RenderType"="Transparent"
            "IgnoreProjector"="True"
        }

        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off
        ZWrite Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;

            float4 _Color;
            float4 _OutlineColor;

            float _OutlineWidth;
            float _Softness;

            float _FireSpeed;
            float _NoiseScale;
            float _Intensity;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.color = v.color;
                return o;
            }

            float rand(float2 p)
            {
                return frac(sin(dot(p, float2(12.9898,78.233))) * 43758.5453);
            }

            float noise(float2 p)
            {
                float2 i = floor(p);
                float2 f = frac(p);

                float a = rand(i);
                float b = rand(i + float2(1,0));
                float c = rand(i + float2(0,1));
                float d = rand(i + float2(1,1));

                float2 u = f * f * (3.0 - 2.0 * f);

                return lerp(a,b,u.x) +
                       (c-a)*u.y*(1-u.x) +
                       (d-b)*u.x*u.y;
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 uv = i.uv;

                float4 tex = tex2D(_MainTex, uv) * _Color;

                float alpha = tex.a;

                // =========================
                // SDF APPROX (fake but good)
                // =========================

                float2 texel = float2(1.0/256.0, 1.0/256.0); // safe fallback

                float a = tex2D(_MainTex, uv + float2(_OutlineWidth,0)).a;
                float b = tex2D(_MainTex, uv - float2(_OutlineWidth,0)).a;
                float c = tex2D(_MainTex, uv + float2(0,_OutlineWidth)).a;
                float d = tex2D(_MainTex, uv - float2(0,_OutlineWidth)).a;

                float outline = saturate((a + b + c + d) - alpha);

                // =========================
                // FIRE ANIMATION
                // =========================

                float time = _Time.y * _FireSpeed;

                float n = noise(uv * _NoiseScale + time);

                float fire = pow(n, 3.0);

                fire *= outline;

                float3 fireColor = _OutlineColor.rgb * fire * _Intensity;

                // =========================
                // FINAL
                // =========================

                float3 finalCol = tex.rgb + fireColor;

                return float4(finalCol, max(tex.a, outline));
            }

            ENDHLSL
        }
    }
}