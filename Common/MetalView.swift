//
//  MetalView.swift
//  C-swifty4 Mac
//
//  Created by Fabio on 10/11/2017.
//  Copyright © 2017 orange in a day. All rights reserved.
//

import Foundation
import MetalKit

class MetalView: MTKView {
    
    fileprivate var pipelineState: MTLRenderPipelineState!
    fileprivate var commandQueue: MTLCommandQueue!
    fileprivate var buffer: MTLBuffer!
    fileprivate var texture: MTLTexture!
    fileprivate var currentData: UnsafePointer<UInt32>?
    fileprivate var textureSize: CGSize = .zero
    fileprivate var vertexData: [Float] = []
    fileprivate var scaleFilter: ScaleFilter!
    
    required init(coder: NSCoder) {
        super.init(coder: coder)

        device = MTLCreateSystemDefaultDevice()
        delegate = self
        
        let library = device!.makeDefaultLibrary()!
        let pipeline = MTLRenderPipelineDescriptor()
        pipeline.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipeline.vertexFunction = library.makeFunction(name: "vertex_main")
        pipeline.fragmentFunction = library.makeFunction(name: "fragment_main")
        pipelineState = try! device!.makeRenderPipelineState(descriptor: pipeline)
        commandQueue = device!.makeCommandQueue()

        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: 512, height: 512, mipmapped: false)
        texture = device?.makeTexture(descriptor: textureDescriptor)
        
        scaleFilter = ScaleFilter(device: device!, library: library)
    }
    
    func setTextureSize(_ size: CGSize, safeArea: (top: Int, left: Int, bottom: Int, right: Int)) {
        textureSize = size
        vertexData = [Float(safeArea.left) / 512.0, 1.0 - (512.0 - Float(size.height) + Float(safeArea.bottom)) / 512.0,
                      1.0 - (512.0 - Float(size.width) + Float(safeArea.right)) / 512.0, 1.0 - (512.0 - Float(size.height) + Float(safeArea.bottom)) / 512.0,
                      Float(safeArea.left) / 512.0, Float(safeArea.top) / 512.0,
                      1.0 - (512.0 - Float(size.width) + Float(safeArea.right)) / 512.0, Float(safeArea.top) / 512.0]
    }
    
    internal func setData(_ data: UnsafePointer<UInt32>) {
        currentData = data
    }
    
}

extension MetalView: MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }
    
    func draw(in view: MTKView) {
        guard let currentData = currentData, let currentRenderPassDescriptor = view.currentRenderPassDescriptor, let currentDrawable = view.currentDrawable else { return }

        texture.replace(region: MTLRegionMake2D(0, 0, Int(textureSize.width), Int(textureSize.height)), mipmapLevel: 0, withBytes: currentData, bytesPerRow: Int(textureSize.width) * 4)
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        scaleFilter.apply(to: texture, with: commandBuffer)
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: currentRenderPassDescriptor)!
        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
        encoder.setFragmentBytes([Float(currentDrawable.texture.width), Float(currentDrawable.texture.height)], length: 2 * MemoryLayout<Float>.stride, index: 0)
        encoder.setFragmentTexture(scaleFilter.texture, index: 0)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
        encoder.endEncoding()
        
        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
    }
    
}
