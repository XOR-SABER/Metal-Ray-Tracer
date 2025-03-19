//
//  MetalView.swift
//  Metal-Ray-Tracer
//
//  Created by Alexander Betancourt on 3/18/25.
//

import MetalKit
import SwiftUI

struct MetalView: UIViewRepresentable {
    
    @State private var renderer: MetalRenderer = MetalRenderer()
    func makeUIView(context: Context) -> some UIView {
        let view = MTKView()
        
        view.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        
        view.device = renderer.device
        view.delegate = renderer
        
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
}
