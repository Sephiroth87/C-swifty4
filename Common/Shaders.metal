//
//  Shaders.metal
//  C-swifty4 Mac
//
//  Created by Fabio on 10/11/2017.
//  Copyright © 2017 orange in a day. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

typedef struct {
    float4 renderedCoordinate [[position]];
    float2 textureCoordinate;
} TextureMappingVertex;

vertex TextureMappingVertex vertex_main(unsigned int vertex_id [[ vertex_id ]], constant float4x2& textureCoordinates [[ buffer(0) ]]) {
    float4x4 renderedCoordinates = float4x4(float4( -1.0, -1.0, 0.0, 1.0 ),      /// (x, y, depth, W)
                                            float4(  1.0, -1.0, 0.0, 1.0 ),
                                            float4( -1.0,  1.0, 0.0, 1.0 ),
                                            float4(  1.0,  1.0, 0.0, 1.0 ));
    TextureMappingVertex outVertex;
    outVertex.renderedCoordinate = renderedCoordinates[vertex_id];
    outVertex.textureCoordinate = textureCoordinates[vertex_id];
    
    return outVertex;
}

fragment half4 fragment_main(TextureMappingVertex vert [[stage_in]],
                             texture2d<float, access::sample> texture [[texture(0)]],
                             constant float2& textureSize [[ buffer(0) ]])
{
    // Use nearest interpolation on the pixels at the edge of the texture, so external color doesn't bleed inside
    if (vert.renderedCoordinate.y >= textureSize.y - 1.0 || vert.renderedCoordinate.x >= textureSize.x - 1.0) {
        constexpr sampler s(address::clamp_to_edge, filter::nearest);
        return half4(texture.sample(s, vert.textureCoordinate));
    }
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    return half4(texture.sample(s, vert.textureCoordinate));
}

kernel void scale(texture2d<half, access::read>  inTexture   [[ texture(0) ]],
                   texture2d<half, access::write> outTexture  [[ texture(1) ]],
                   uint2                          gid         [[ thread_position_in_grid ]]) {
    half4 result = inTexture.read(uint2(gid.x / 2, gid.y / 2));
    outTexture.write(result, gid);
}
