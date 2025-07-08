//
//  vertex_shader.metal
//  PerformanceTest
//
//  Created by Zheng, Haiqiang (Jason) on 2024/7/4.
//


#include <metal_stdlib>
#import "ShaderTypes.h"

using namespace metal;

typedef struct
{
    float4 clipSpacePosition [[position]];
    float3 pixelColor;
    float2 textureCoordinate;
    
} RasterizerData;

vertex RasterizerData // 顶点
vertexShader(uint vertexID [[ vertex_id ]],
             constant MTVertex *vertexArray [[ buffer(MTVertexInputIndexVertices) ]],
             constant MTMatrix *matrix [[ buffer(MTVertexInputIndexMatrix) ]]) {
    RasterizerData out;
    out.clipSpacePosition = matrix->projectionMatrix * matrix->modelViewMatrix * vertexArray[vertexID].position;
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
    out.pixelColor = vertexArray[vertexID].color;
    
    return out;
}

fragment float4 // 片元
samplingShader(RasterizerData input [[stage_in]],
               texture2d<half> textureColor [[ texture(MTFragmentInputIndexTexture) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    
//    half4 colorTex = textureColor.sample(textureSampler, input.textureCoordinate);
    half4 colorTex = half4(input.pixelColor.x, input.pixelColor.y, input.pixelColor.z, 1);
    return float4(colorTex);
}
