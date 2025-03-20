//
//  Camera.swift
//  Metal-Ray-Tracer
//
//  Created by Alexander Betancourt on 3/19/25.
//
import MetalKit

class Camera {
    var position: SIMD3<Float>
    var rotation: SIMD3<Float>
    var sensitivity: Float = 0.05;
    
    init(position: SIMD3<Float> = SIMD3<Float>(0, 0, -10), rotation: SIMD3<Float> = SIMD3<Float>(0, 0, 0)) {
        self.position = position
        self.rotation = rotation
    }
    
    func updateRotation(from gyroVector: SIMD3<Float>) {
        let sensitivity: Float = 0.075
         rotation.x -= gyroVector.x * sensitivity
         rotation.y -= gyroVector.y * sensitivity
         rotation.z += gyroVector.z * sensitivity
     }
    
    func getViewMatrix() -> simd_float4x4 {
        let rollMatrix = rotationMatrixX(angle: rotation.x)
        let pitchMatrix = rotationMatrixY(angle: rotation.y)
        let yawMatrix = rotationMatrixZ(angle: rotation.z)
        
        let rotationMatrix = yawMatrix * pitchMatrix * rollMatrix
        let translationMatrix = translationMatrix(translation: -position)
        
        return rotationMatrix * translationMatrix
    }
}
