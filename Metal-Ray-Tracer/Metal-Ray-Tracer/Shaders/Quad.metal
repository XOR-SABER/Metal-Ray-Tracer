//
//  Quad.metal
//  Metal-Ray-Tracer
//
//  Created by Alexander Betancourt on 3/18/25.
//

#include <metal_stdlib>
using namespace metal;

// Input struct for vertex shader
struct Vertex {
    float4 position [[attribute(0)]];
    float4 color [[attribute(1)]];
};

// Input struct for fragment shader
struct FragmentInput {
    float4 position [[position]];
    float2 uv;
};

// Vertex shader
vertex FragmentInput vertex_main(Vertex v [[stage_in]]) {
    return {
        .position {v.position},
        .uv {(v.position.xy + 1.0) / 2.0}
    };
}

// Just makes quad we are rendering to
fragment float4 fragment_main(FragmentInput in [[stage_in]], texture2d<float> tex [[texture(0)]]) {
    constexpr sampler texSampler(mip_filter::linear, mag_filter::linear, min_filter::linear);
    return tex.sample(texSampler, in.uv);
}

