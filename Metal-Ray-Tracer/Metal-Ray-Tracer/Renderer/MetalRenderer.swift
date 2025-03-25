//
//  MetalRenderer.swift
//  Metal-Ray-Tracer
//
//  Created by Alexander Betancourt on 3/18/25.
//
import MetalKit

class MetalRenderer:  NSObject, MTKViewDelegate {
    // Device
    let device: MTLDevice
    // Buffers
    let indexBuffer: MTLBuffer
    let vertexBuffer: MTLBuffer
    let sphereBuffer: MTLBuffer
    let viewMatrixBuffer: MTLBuffer
    let sphereCountBuffer: MTLBuffer
    // Command Queue
    let commandQueue: MTLCommandQueue
    // Pipeline state
    let pipelineState: MTLRenderPipelineState
    // Compute pipeline state
    let computePipelineState: MTLComputePipelineState
    
    // Texture variable
    var texture: MTLTexture
    
    // Camera
    var camera = Camera()
    
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
    
    let spheres: [Sphere] = Sphere.generateRandomSpheres(count: 256)
    
    override init() {
        device = MetalRenderer.createMetalDevice()
        commandQueue = MetalRenderer.createCommandQueue(device: device)
        viewMatrixBuffer = MetalRenderer.create4x4MatrixBuffer(with: device)
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
        
        GyroManager.instance.startGyroUpdates(for: camera)
        super.init();
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
        
        var viewMatrix = camera.getViewMatrix()
        memcpy(viewMatrixBuffer.contents(), &viewMatrix, MemoryLayout<simd_float4x4>.size)
        
        
        // Send params to Compute shader
        computeEncoder.setComputePipelineState(computePipelineState)
        computeEncoder.setTexture(texture, index: 0)
        computeEncoder.setBuffer(sphereBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(sphereCountBuffer, offset: 0, index: 1)
        computeEncoder.setBuffer(viewMatrixBuffer, offset: 0, index: 2)
        
        // Let 32 * 32 threads run this
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
    
    // Creates the device to render on
    private static func createMetalDevice() -> MTLDevice {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal device not available")
        }
        return device
    }
    
    // Create Command queue
    private static func createCommandQueue(device: MTLDevice) -> MTLCommandQueue {
        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("Command queue not available")
        }
        return commandQueue
    }
    
    // Creates buffer for vertexes
    private static func createVertexBuffer(device: MTLDevice, containing vertices: [Vertex]) -> MTLBuffer {
        guard let vertexBuffer = device.makeBuffer(bytes: vertices, length: MemoryLayout<Vertex>.stride * vertices.count, options: []) else {
            fatalError("Unable to create vertex buffer")
        }
        return vertexBuffer
    }
    
    // Complies .metal files
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
    
    //Creates texture
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
    
    //Creates buffer for vertex indiexes
    private static func createIndexBuffer(device: MTLDevice, containing indices: [UInt16]) -> MTLBuffer {
        guard let indexBuffer = device.makeBuffer(bytes: indices, length: MemoryLayout<UInt16>.stride * indices.count, options: []) else {
            fatalError("Failed to create index buffer")
        }
        return indexBuffer
    }
    
    // Creates the pipeline state
    private static func createComputePipelineState(with device: MTLDevice, function: MTLFunction) -> MTLComputePipelineState {
        do {
            return try device.makeComputePipelineState(function: function)
        } catch {
            fatalError("Failed to create compute pipeline: \(error.localizedDescription)")
        }
    }
    
    // Send Sphere buffer to gpu
    private static func createSphereBuffer(with device: MTLDevice, containing spheres: [Sphere]) -> MTLBuffer {
        let stride = MemoryLayout<Sphere>.stride * spheres.count
        guard let sphereBuffer = device.makeBuffer(bytes: spheres, length: stride, options: []) else {
            fatalError("Failed to create sphere buffer")
        }
        return sphereBuffer
    }
    
    // Send Sphere count buffer to gpu
    private static func createSphereCountBuffer(with device: MTLDevice, containing sphereCount: Int) -> MTLBuffer {
        var count = sphereCount
        let stride = MemoryLayout<Int>.stride
        guard let sphereCountBuffer = device.makeBuffer(bytes: &count, length: stride, options: []) else {
            fatalError("Failed to create sphere count buffer")
        }
        return sphereCountBuffer
    }
    
    // Send matrix buffer to gpu
    private static func create4x4MatrixBuffer(with device: MTLDevice) -> MTLBuffer {
        guard let buffer = device.makeBuffer(length: MemoryLayout<simd_float4x4>.stride, options: .storageModeShared) else {
            fatalError("Failed to create matrix buffer")
        }
        return buffer
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}
