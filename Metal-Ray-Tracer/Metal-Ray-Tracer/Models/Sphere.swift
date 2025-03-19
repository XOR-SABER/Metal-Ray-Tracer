//
//  Sphere.swift
//  Metal-Ray-Tracer
//
//  Created by Alexander Betancourt on 3/18/25.
//
import MetalKit

struct Sphere {
    var center: SIMD4<Float>  // Position (x, y, z, w)
    var color: SIMD4<Float>   // RGBA color
    var radius: Float         // Sphere radius

    static func buildBufferLayout() -> MTLBufferLayoutDescriptor {
        let layoutDescriptor = MTLBufferLayoutDescriptor()

        layoutDescriptor.stride = MemoryLayout<Sphere>.stride
        return layoutDescriptor
    }

    static func buildBufferDescriptor() -> MTLVertexDescriptor {
        let descriptor = MTLVertexDescriptor()

        descriptor.attributes[0].format = .float4
        descriptor.attributes[0].bufferIndex = 0
        descriptor.attributes[0].offset = MemoryLayout<Sphere>.offset(of: \.center)!

        descriptor.attributes[1].format = .float4
        descriptor.attributes[1].bufferIndex = 0
        descriptor.attributes[1].offset = MemoryLayout<Sphere>.offset(of: \.color)!

        descriptor.attributes[2].format = .float
        descriptor.attributes[2].bufferIndex = 0
        descriptor.attributes[2].offset = MemoryLayout<Sphere>.offset(of: \.radius)!

        descriptor.layouts[0].stride = MemoryLayout<Sphere>.stride

        return descriptor
    }
}
