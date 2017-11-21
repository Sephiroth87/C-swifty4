//
//  ScaleFilter.swift
//  C-swifty4 Mac
//
//  Created by Fabio on 16/11/2017.
//  Copyright © 2017 orange in a day. All rights reserved.
//

import MetalKit

// Simple 2x texture scaler
// TODO: Maybe implement other scaling factors if the drawing surface is closer to one of them (less blur when scaling)
class ScaleFilter {
    
    internal let texture: MTLTexture
    private let kernel: MTLComputePipelineState
    private let threadGroupSize = MTLSizeMake(16, 16, 1)
    private let threadGroupCount = MTLSizeMake(64, 64, 1)
    
    init(device: MTLDevice, library: MTLLibrary, usesMtlBuffer: Bool) {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: 1024, height: 1024, mipmapped: false)
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        if usesMtlBuffer, #available(OSX 10.13, iOS 8.0, tvOS 9.0, *) {
            let buffer = device.makeBuffer(length: 1024 * 1024 * 4, options: [])!
            texture = buffer.makeTexture(descriptor: textureDescriptor, offset: 0, bytesPerRow: 1024 * 4)!
        } else {
            texture = device.makeTexture(descriptor: textureDescriptor)!
        }
        let function = library.makeFunction(name: "scale")!
        kernel = try! device.makeComputePipelineState(function: function)
    }
    
    func apply(to: MTLTexture, with commandBuffer: MTLCommandBuffer) {
        let encoder = commandBuffer.makeComputeCommandEncoder()
        encoder?.setComputePipelineState(kernel)
        encoder?.setTexture(to, index: 0)
        encoder?.setTexture(texture, index: 1)
        encoder?.dispatchThreadgroups(threadGroupCount, threadsPerThreadgroup: threadGroupSize)
        encoder?.endEncoding()
    }
    
}
