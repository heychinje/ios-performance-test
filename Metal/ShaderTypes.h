//
//  ShaderTypes.h
//  PerformanceTest
//
//  Created by Zheng, Haiqiang (Jason) on 2024/7/5.
//

#include <simd/simd.h>

typedef struct
{
    vector_float4 position;
    vector_float3 color;
    vector_float2 textureCoordinate;
} MTVertex;


typedef struct
{
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 modelViewMatrix;
} MTMatrix;



typedef enum MTVertexInputIndex
{
    MTVertexInputIndexVertices     = 0,
    MTVertexInputIndexMatrix       = 1,
} MTVertexInputIndex;



typedef enum MTFragmentInputIndex
{
    MTFragmentInputIndexTexture     = 0,
} MTFragmentInputIndex;

