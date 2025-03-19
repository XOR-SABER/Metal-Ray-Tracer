//
//  MetalRenderer.swift
//  Metal-Ray-Tracer
//
//  Created by Alexander Betancourt on 3/18/25.
//
import MetalKit

class MetalRenderer:  NSObject, MTKViewDelegate {
    
    let vertexBuffer: MTLBuffer
    let indexBuffer: MTLBuffer
    let sphereBuffer: MTLBuffer
    let sphereCountBuffer: MTLBuffer
    let pipelineState: MTLRenderPipelineState
    let computePipelineState: MTLComputePipelineState
    let commandQueue: MTLCommandQueue
    let device: MTLDevice
    var texture: MTLTexture
    
    let vertices: [Vertex] = [
        Vertex(position2D: [  1.0,  1.0], color: [1, 0, 0]), // Top Right
        Vertex(position2D: [ -1.0,  1.0], color: [0, 1, 0]), // Top Left
        Vertex(position2D: [ -1.0, -1.0], color: [0, 0, 1]), // Bottom Left
        Vertex(position2D: [  1.0, -1.0], color: [1, 1, 1])  // Bottom Right
    ]
    
    let indices: [UInt16] = [
        0, 1, 2, // First Triangle
        2, 3, 0  // Second Triangle
    ]
    
    let spheres: [Sphere] = MetalRenderer.generateRandomSpheres(count: 256)



    
    override init() {
        device = MetalRenderer.createMetalDevice()
        commandQueue = MetalRenderer.createCommandQueue(device: device)
        vertexBuffer = MetalRenderer.createVertexBuffer(device: device, containing: vertices)
        indexBuffer = MetalRenderer.createIndexBuffer(device: device, containing: indices)
        sphereBuffer = MetalRenderer.createSphereBuffer(with: device, containing: spheres)
        sphereCountBuffer = MetalRenderer.createSphereCountBuffer(with: device, containing: spheres.count)
        
        texture = MetalRenderer.createTexture(device: device, width: 512, height: 512)
        
        let descriptor = Vertex.buildDefaultVertexDescriptor()
        let library = MetalRenderer.createDefaultMetalLibary(device: device)
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "vertex_main")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragment_main")
        pipelineDescriptor.vertexDescriptor = descriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineState = MetalRenderer.createPipelineState(with: device, from: pipelineDescriptor)
        
        let computeFunction = library.makeFunction(name: "compute_shader")!
        computePipelineState = MetalRenderer.createComputePipelineState(with: device, function: computeFunction)
        
        super.init();
    }
    
    
    private static func generateRandomSpheres(count: Int, minRadius: Float = 0.8, maxRadius: Float = 2.5,
                               minZ: Float = 10.0, maxZ: Float = 50.0, spacing: Float = 6.0) -> [Sphere] {
        var spheres: [Sphere] = []
        
        // Estimate a grid size based on the count
        let gridSize = Int(ceil(sqrt(Float(count)))) // Create a roughly square grid
        let startX = -Float(gridSize) * spacing / 2
        let startY = -Float(gridSize) * spacing / 2
        
        var index = 0
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if index >= count { break }  // Stop when we reach the desired count

                // Generate sphere positions in a structured grid with randomness
                let randomOffsetX = Float.random(in: -spacing/2 ... spacing/2)
                let randomOffsetY = Float.random(in: -spacing/2 ... spacing/2)
                let randomOffsetZ = Float.random(in: -2.0 ... 2.0) // Minor depth variation

                let x = startX + Float(col) * spacing + randomOffsetX
                let y = startY + Float(row) * spacing + randomOffsetY
                let z = Float.random(in: minZ...maxZ) + randomOffsetZ // Keep spheres at various depths

                let randomRadius = Float.random(in: minRadius...maxRadius)

                let randomColor = SIMD4<Float>(
                    Float.random(in: 0.2...1.0),  // Red
                    Float.random(in: 0.2...1.0),  // Green
                    Float.random(in: 0.2...1.0),  // Blue
                    1.0                           // Alpha (fully opaque)
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


    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer() else {
            fatalError("Unable to setup command buffer")
        }

        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            fatalError("Failed to create compute command encoder")
        }
        
        computeEncoder.setComputePipelineState(computePipelineState)
        computeEncoder.setTexture(texture, index: 0)
        computeEncoder.setBuffer(sphereBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(sphereCountBuffer, offset: 0, index: 1)
        // Let 16 * 16 threads run this
        let threadGroupSize = MTLSize(width: 32, height: 32, depth: 1)
        let threadGroups = MTLSize(width: texture.width / threadGroupSize.width,
                                   height: texture.height / threadGroupSize.height,
                                   depth: 1)
        
        computeEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        computeEncoder.endEncoding()

        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            fatalError("Failed to create render command encoder")
        }

        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentTexture(texture, index: 0)
        renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indices.count, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
        
        renderEncoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    private static func createMetalDevice() -> MTLDevice {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal device not available")
        }
        return device
    }
    
    private static func createCommandQueue(device: MTLDevice) -> MTLCommandQueue {
        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("Command queue not available")
        }
        return commandQueue
    }
    
    private static func createVertexBuffer(device: MTLDevice, containing vertices: [Vertex]) -> MTLBuffer {
        guard let vertexBuffer = device.makeBuffer(bytes: vertices, length: MemoryLayout<Vertex>.stride * vertices.count, options: []) else {
            fatalError("Unable to create vertex buffer")
        }
        return vertexBuffer
    }
    
    private static func createDefaultMetalLibary(device: MTLDevice) -> MTLLibrary {
        guard let defaultLibrary = device.makeDefaultLibrary() else {
            fatalError( "No .metal files in the Xcode project")
        }
        
        return defaultLibrary
    }
    
    private static func createPipelineState(with device: MTLDevice, from descriptor : MTLRenderPipelineDescriptor) -> MTLRenderPipelineState {
        do {
            return try device.makeRenderPipelineState(descriptor: descriptor)
        } catch let error {
            fatalError("Failed to create the pipeline state: \(error.localizedDescription)")
        }
    }
    private static func createTexture(device: MTLDevice, width: Int, height: Int) -> MTLTexture {
        let descriptor = MTLTextureDescriptor()
        descriptor.pixelFormat = .bgra8Unorm
        descriptor.width = width
        descriptor.height = height
        descriptor.usage = [.shaderRead, .shaderWrite]
        descriptor.storageMode = .private // Optimized for GPU usage
        
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            fatalError("Failed to create texture")
        }
        return texture
    }
    
    private static func createIndexBuffer(device: MTLDevice, containing indices: [UInt16]) -> MTLBuffer {
        guard let indexBuffer = device.makeBuffer(bytes: indices, length: MemoryLayout<UInt16>.stride * indices.count, options: []) else {
            fatalError("Failed to create index buffer")
        }
        return indexBuffer
    }
    
    private static func createComputePipelineState(with device: MTLDevice, function: MTLFunction) -> MTLComputePipelineState {
        do {
            return try device.makeComputePipelineState(function: function)
        } catch {
            fatalError("Failed to create compute pipeline: \(error.localizedDescription)")
        }
    }
    
    private static func createSphereBuffer(with device: MTLDevice, containing spheres: [Sphere]) -> MTLBuffer {
        let stride = MemoryLayout<Sphere>.stride * spheres.count
        guard let sphereBuffer = device.makeBuffer(bytes: spheres, length: stride, options: []) else {
            fatalError("Failed to create sphere buffer")
        }
        return sphereBuffer
    }


    
    private static func createSphereCountBuffer(with device: MTLDevice, containing sphereCount: Int) -> MTLBuffer {
        var count = sphereCount
        let stride = MemoryLayout<Int>.stride
        guard let sphereCountBuffer = device.makeBuffer(bytes: &count, length: stride, options: []) else {
            fatalError("Failed to create sphere count buffer")
        }
        return sphereCountBuffer
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}
