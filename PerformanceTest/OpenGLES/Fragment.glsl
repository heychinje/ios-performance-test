
varying lowp vec4 varyColor;
varying lowp vec2 varyTex;

uniform sampler2D texture;

void main()
{
    gl_FragColor = varyColor;
//    gl_FragColor = texture2D(texture, varyTex) * varyColor;
}

