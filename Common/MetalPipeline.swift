//
//  MetalPipeline.swift
//  C-swifty4
//
//  Created by Fabio on 20/11/2017.
//  Copyright © 2017 orange in a day. All rights reserved.
//

import MetalKit

class MetalPipeline {
    private let texture: MTLTexture
    private let scaleFilter: ScaleFilter
    
    let device: MTLDevice
    let pipelineState: MTLRenderPipelineState
    let commandQueue: MTLCommandQueue
    let processedTexture: MTLTexture
    
    init(usesMtlBuffer: Bool = false) {
        device = MTLCreateSystemDefaultDevice()!
        let library = device.makeDefaultLibrary()!
        let pipeline = MTLRenderPipelineDescriptor()
        pipeline.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipeline.vertexFunction = library.makeFunction(name: "vertex_main")
        pipeline.fragmentFunction = library.makeFunction(name: "fragment_main")
        pipelineState = try! device.makeRenderPipelineState(descriptor: pipeline)
        commandQueue = device.makeCommandQueue()!
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: 512, height: 512, mipmapped: false)
        texture = device.makeTexture(descriptor: textureDescriptor)!

        scaleFilter = ScaleFilter(device: device, library: library, usesMtlBuffer: usesMtlBuffer)
        processedTexture = scaleFilter.texture
    
        if usesMtlBuffer && processedTexture.buffer == nil {
            fatalError("Processed texture needs to have a backing buffer")
        }
    }
    
    func process(data: UnsafePointer<UInt32>, size: CGSize, additionalCommands: ((MTLCommandBuffer) -> Void)? = nil) {
        texture.replace(region: MTLRegionMake2D(0, 0, Int(size.width), Int(size.height)), mipmapLevel: 0, withBytes: data, bytesPerRow: Int(size.width) * 4)
        let commandBuffer = commandQueue.makeCommandBuffer()!
        scaleFilter.apply(to: texture, with: commandBuffer)
        additionalCommands?(commandBuffer)
        commandBuffer.commit()
    }
    
}
