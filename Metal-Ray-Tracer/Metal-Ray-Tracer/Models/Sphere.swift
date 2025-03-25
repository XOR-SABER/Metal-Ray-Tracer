//
//  Sphere.swift
//  Metal-Ray-Tracer
//
//  Created by Alexander Betancourt on 3/18/25.
//
import MetalKit

struct Sphere {
    var center: SIMD4<Float>
    var color: SIMD4<Float>   // RGBA color
    var radius: Float

    // Builds the buffer layour for sphere
    static func buildBufferLayout() -> MTLBufferLayoutDescriptor {
        let layoutDescriptor = MTLBufferLayoutDescriptor()

        layoutDescriptor.stride = MemoryLayout<Sphere>.stride
        return layoutDescriptor
    }
    
    // Bulids the buffer description for Sphere
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
    
    // This one is just shitty.
    static func generateRandomSpheres(count: Int, minRadius: Float = 0.8, maxRadius: Float = 2.5,
                               minZ: Float = 10.0, maxZ: Float = 50.0, spacing: Float = 6.0) -> [Sphere] {
        var spheres: [Sphere] = []
        
        let gridSize = Int(ceil(sqrt(Float(count))))
        let startX = -Float(gridSize) * spacing / 2
        let startY = -Float(gridSize) * spacing / 2
        
        var index = 0
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if index >= count { break }

                let randomOffsetX = Float.random(in: -spacing/2 ... spacing/2)
                let randomOffsetY = Float.random(in: -spacing/2 ... spacing/2)
                let randomOffsetZ = Float.random(in: -2.0 ... 2.0)

                let x = startX + Float(col) * spacing + randomOffsetX
                let y = startY + Float(row) * spacing + randomOffsetY
                let z = Float.random(in: minZ...maxZ) + randomOffsetZ

                let randomRadius = Float.random(in: minRadius...maxRadius)

                let randomColor = SIMD4<Float>(
                    Float.random(in: 0.2...1.0),
                    Float.random(in: 0.2...1.0),
                    Float.random(in: 0.2...1.0),
                    1.0
                )

                let sphere = Sphere(
                    center: SIMD4<Float>(x, y, z, 1.0),
                    color: randomColor,
                    radius: randomRadius
                )

                spheres.append(sphere)
                index += 1
            }
        }

        return spheres
    }
}
