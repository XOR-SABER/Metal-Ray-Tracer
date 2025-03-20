//
//  GyroManager.swift
//  Metal-Ray-Tracer
//
//  Created by Alexander Betancourt on 3/19/25.
//

import CoreMotion

public class GyroManager {
    public static let instance = GyroManager()
    private let motionManager = CMMotionManager()
    private var camera: Camera?
    
    private init() {}
    
    func startGyroUpdates(for camera: Camera) {
        self.camera = camera
        
        guard motionManager.isGyroAvailable else {
            fatalError("Gyroscope is not available")
        }
        
        motionManager.gyroUpdateInterval = 0.05
        motionManager.startGyroUpdates(to: .main) { [weak self] (gyroData, error) in
            guard let data = gyroData, let self = self, let camera = self.camera else { return }
            
            let gyroVector = SIMD3<Float>(
                Float(data.rotationRate.x), // Roll
                Float(data.rotationRate.y), // Pitch
                Float(data.rotationRate.z)  // Yaw
            )
            
            camera.updateRotation(from: gyroVector)
        }
    }
    
    func stopGyroUpdates() {
        motionManager.stopGyroUpdates()
    }
}
