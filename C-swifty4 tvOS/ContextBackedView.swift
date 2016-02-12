//
//  ContextBackedView.swift
//  C-swifty4 iOS
//
//  Created by Fabio Ritrovato on 10/01/2015.
//  Copyright (c) 2015 orange in a day. All rights reserved.
//

import UIKit

private class ContextBackedLayer: CALayer {
    
    private var context: CGContextRef
    
    required init?(coder aDecoder: NSCoder) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        context = CGBitmapContextCreate(nil, 418, 235, 8, 1680, colorSpace, CGImageAlphaInfo.PremultipliedLast.rawValue)!
        super.init(coder: aDecoder)
        self.actions = ["contents": NSNull()]
    }
    
    override init() {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        context = CGBitmapContextCreate(nil, 418, 235, 8, 1680, colorSpace, CGImageAlphaInfo.PremultipliedLast.rawValue)!
        super.init()
        self.actions = ["contents": NSNull()]
    }
    
    override func display() {
        let CGImage = CGBitmapContextCreateImage(context)
        self.contents = CGImage
    }
    
    private func setData(data: UnsafePointer<UInt32>) {
        let address = CGBitmapContextGetData(context)
        memcpy(address, data, 418 * 235 * 4)
        let cgImage = CGBitmapContextCreateImage(context)
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
    
    override class func layerClass() -> AnyClass {
        return ContextBackedLayer.self
    }

    override func drawRect(rect: CGRect) {
    }

    internal func setData(data: UnsafePointer<UInt32>) {
        let layer = self.layer as! ContextBackedLayer
        layer.setData(data)
    }
    
}
