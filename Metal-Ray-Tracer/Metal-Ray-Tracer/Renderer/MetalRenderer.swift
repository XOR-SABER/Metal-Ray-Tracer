//
//  MetalRenderer.swift
//  Metal-Ray-Tracer
//
//  Created by Alexander Betancourt on 3/18/25.
//
import MetalKit

class MetalRenderer:  NSObject, MTKViewDelegate {
    
    let vertexBufffer: MTLBuffer
    let indexBuffer: MTLBuffer
    let pipelineState: MTLRenderPipelineState
    let commandQueue: MTLCommandQueue
    let device: MTLDevice
    
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
    
    override init() {
        device = MetalRenderer.createMetalDevice()
        commandQueue = MetalRenderer.createCommandQueue(device: device)
        vertexBufffer = MetalRenderer.createVertexBuffer(device: device, containing: vertices)
        indexBuffer = MetalRenderer.createIndexBuffer(device: device, containing: indices)
        
        let descriptor = Vertex.buildDefaultVertexDescriptor()
        let library = MetalRenderer.createDefaultMetalLibary(device: device)
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "vertex_main")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragment_main")
        pipelineDescriptor.vertexDescriptor = descriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        pipelineState = MetalRenderer.createPipelineState(with: device, from: pipelineDescriptor)
        
        super.init();
    }
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    func draw(in view: MTKView) {
        if let drawable = view.currentDrawable, let renderPassDescriptor = view.currentRenderPassDescriptor {
            guard let commandBuffers = commandQueue.makeCommandBuffer(), let renderCommandEncoder = commandBuffers.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
                fatalError("Unable to setup objects for render encoding")
            }
            
            renderCommandEncoder.setRenderPipelineState(pipelineState)
            renderCommandEncoder.setVertexBuffer(vertexBufffer, offset: 0, index: 0)
            renderCommandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indices.count, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
            renderCommandEncoder.endEncoding()
            
            commandBuffers.present(drawable)
            commandBuffers.commit()
        }
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
            fatalError("Could not create the pipeline state: \(error.localizedDescription)")
        }
    }
    private static func createIndexBuffer(device: MTLDevice, containing indices: [UInt16]) -> MTLBuffer {
        guard let indexBuffer = device.makeBuffer(bytes: indices, length: MemoryLayout<UInt16>.stride * indices.count, options: []) else {
            fatalError("Unable to create index buffer")
        }
        return indexBuffer
    }
}
