attribute vec4 position;
attribute vec4 positionColor;
attribute vec2 texCoord;

uniform mat4 projectionMatrix;
uniform mat4 modelViewMatrix;

varying lowp vec4 varyColor;
varying lowp vec2 varyTex;

void main()
{
    gl_Position = projectionMatrix * modelViewMatrix * position;
    varyColor = positionColor;
    varyTex = texCoord;
}

