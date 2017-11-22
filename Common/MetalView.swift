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
    
    fileprivate let metalPipeline = MetalPipeline()
    fileprivate var currentData: UnsafePointer<UInt32>?
    fileprivate var textureSize: CGSize = .zero
    fileprivate var vertexData: [Float] = []
    
    required init(coder: NSCoder) {
        super.init(coder: coder)

        device = metalPipeline.device
        delegate = self
    }
    
    func setTextureSize(_ size: CGSize, safeArea: (top: Int, left: Int, bottom: Int, right: Int)) {
        textureSize = size
        let xStart: Float = Float(safeArea.left) / 512.0
        let xEnd: Float = 1.0 - (512.0 - Float(size.width) + Float(safeArea.right)) / 512.0
        let yStart: Float = Float(safeArea.top) / 512.0
        let yEnd: Float = 1.0 - (512.0 - Float(size.height) + Float(safeArea.bottom)) / 512.0
        vertexData = [xStart, yEnd,
                      xEnd, yEnd,
                      xStart, yStart,
                      xEnd, yStart]
    }
    
    internal func setData(_ data: UnsafePointer<UInt32>) {
        currentData = data
    }
    
}

extension MetalView: MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }
    
    func draw(in view: MTKView) {
        guard let currentData = currentData else { return }
        
        metalPipeline.process(data: currentData, size: textureSize) {
            guard let currentRenderPassDescriptor = view.currentRenderPassDescriptor, let currentDrawable = view.currentDrawable else { return }
            let encoder = $0.makeRenderCommandEncoder(descriptor: currentRenderPassDescriptor)!
            encoder.setRenderPipelineState(self.metalPipeline.pipelineState)
            encoder.setVertexBytes(self.vertexData, length: self.vertexData.count * MemoryLayout<Float>.stride, index: 0)
            encoder.setFragmentBytes([Float(view.drawableSize.width), Float(view.drawableSize.height)], length: 2 * MemoryLayout<Float>.stride, index: 0)
            encoder.setFragmentTexture(self.metalPipeline.processedTexture, index: 0)
            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
            encoder.endEncoding()
            $0.present(currentDrawable)
        }
    }
    
}
