//
//  RotationMatrix.swift
//  Metal-Ray-Tracer
//
//  Created by Alexander Betancourt on 3/20/25.
//

import simd


// Just some linear algebra functions to make some matrixes
func rotationMatrixX(angle: Float) -> simd_float4x4 {
    let c = cos(angle)
    let s = sin(angle)
    
    return simd_float4x4(rows: [
        SIMD4<Float>(1, 0,  0, 0),
        SIMD4<Float>(0, c, -s, 0),
        SIMD4<Float>(0, s,  c, 0),
        SIMD4<Float>(0, 0,  0, 1)
    ])
}

func rotationMatrixY(angle: Float) -> simd_float4x4 {
    let c = cos(angle)
    let s = sin(angle)
    
    return simd_float4x4(rows: [
        SIMD4<Float>( c, 0, s, 0),
        SIMD4<Float>( 0, 1, 0, 0),
        SIMD4<Float>(-s, 0, c, 0),
        SIMD4<Float>( 0, 0, 0, 1)
    ])
}

func rotationMatrixZ(angle: Float) -> simd_float4x4 {
    let c = cos(angle)
    let s = sin(angle)
    
    return simd_float4x4(rows: [
        SIMD4<Float>(c, -s, 0, 0),
        SIMD4<Float>(s,  c, 0, 0),
        SIMD4<Float>(0,  0, 1, 0),
        SIMD4<Float>(0,  0, 0, 1)
    ])
}

func translationMatrix(translation: SIMD3<Float>) -> simd_float4x4 {
    return simd_float4x4(rows: [
        SIMD4<Float>(1, 0, 0, 0),
        SIMD4<Float>(0, 1, 0, 0),
        SIMD4<Float>(0, 0, 1, 0),
        SIMD4<Float>(translation.x, translation.y, translation.z, 1)
    ])
}
