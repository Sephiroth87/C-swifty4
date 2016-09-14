//
//  ContextBackedView.swift
//  C-swifty4 iOS
//
//  Created by Fabio Ritrovato on 10/01/2015.
//  Copyright (c) 2015 orange in a day. All rights reserved.
//

import UIKit

private class ContextBackedLayer: CALayer {
    
    fileprivate var context: CGContext
    
    required init?(coder aDecoder: NSCoder) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        context = CGContext(data: nil, width: 418, height: 235, bitsPerComponent: 8, bytesPerRow: 1680, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        super.init(coder: aDecoder)
        self.actions = ["contents": NSNull()]
    }
    
    override init() {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        context = CGContext(data: nil, width: 418, height: 235, bitsPerComponent: 8, bytesPerRow: 1680, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        super.init()
        self.actions = ["contents": NSNull()]
    }
    
    override func display() {
        let CGImage = context.makeImage()
        self.contents = CGImage
    }
    
    fileprivate func setData(_ data: UnsafePointer<UInt32>) {
        let address = context.data
        memcpy(address, data, 418 * 235 * 4)
        let cgImage = context.makeImage()
        self.contents = cgImage
    }
    
    override var bounds: CGRect {
        didSet {
            var wScale = bounds.width / 418.0
            var hScale = bounds.height / 235.0
            if wScale > hScale {
                wScale /= hScale
                hScale = 1.0
            } else {
                hScale /= wScale
                wScale = 1.0
            }
            self.contentsRect = CGRect(x: (1.0 - wScale) / 2.0, y: (1.0 - hScale) / 2.0, width: wScale, height: hScale)
        }
    }
    
}

class ContextBackedView: UIView {
    
    override class var layerClass : AnyClass {
        return ContextBackedLayer.self
    }

    override func draw(_ rect: CGRect) {
    }

    internal func setData(_ data: UnsafePointer<UInt32>) {
        let layer = self.layer as! ContextBackedLayer
        layer.setData(data)
    }
    
}
