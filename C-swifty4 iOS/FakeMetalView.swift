//
//  FakeMetalView.swift
//  C-swifty4
//
//  Created by Fabio on 20/11/2017.
//  Copyright © 2017 orange in a day. All rights reserved.
//

import UIKit
import MetalKit

class FakeMetalView: UIView {
    
    fileprivate let metalPipeline = MetalPipeline(usesMtlBuffer: true)
    fileprivate let context: CGContext
    fileprivate var currentData: UnsafePointer<UInt32>?
    fileprivate var textureSize: CGSize = .zero
    
    required init?(coder: NSCoder) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        context = CGContext(data: metalPipeline.processedTexture.buffer?.contents(), width: metalPipeline.processedTexture.width, height: metalPipeline.processedTexture.height, bitsPerComponent: 8, bytesPerRow: metalPipeline.processedTexture.width * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        
        super.init(coder: coder)
        
        layer.actions = ["contents": NSNull()]
        
        CADisplayLink(target: self, selector: #selector(update)).add(to: .current, forMode: .defaultRunLoopMode)
    }
    
    func setTextureSize(_ size: CGSize, safeArea: (top: Int, left: Int, bottom: Int, right: Int)) {
        textureSize = size
        let x: Float = Float(safeArea.left) / 512.0
        let width: Float = 1.0 - (512.0 - Float(size.width) + Float(safeArea.right)) / 512.0 - x
        let y: Float = Float(safeArea.top) / 512.0
        let height: Float = 1.0 - (512.0 - Float(size.height) + Float(safeArea.bottom)) / 512.0 - y
        layer.contentsRect = CGRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(width), height: CGFloat(height))
    }
    
    internal func setData(_ data: UnsafePointer<UInt32>) {
        currentData = data
    }
    
    @objc private func update() {
        guard let currentData = currentData else { return }

        metalPipeline.process(data: currentData, size: textureSize)
        
        layer.contents = context.makeImage()
    }
    
}
