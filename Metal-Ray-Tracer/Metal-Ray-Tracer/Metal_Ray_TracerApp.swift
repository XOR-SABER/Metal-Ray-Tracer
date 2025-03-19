//
//  Metal_Ray_TracerApp.swift
//  Metal-Ray-Tracer
//
//  Created by Alexander Betancourt on 3/18/25.
//

import SwiftUI

@main
struct Metal_Ray_Tracer_App: App {
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                MetalView().aspectRatio(1, contentMode: .fill)
            }
        }
    }
}


