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
        context = CGBitmapContextCreate(nil, 420, 235, 8, 1680, colorSpace, CGImageAlphaInfo.PremultipliedLast.rawValue)!
        super.init(coder: aDecoder)
        self.actions = ["contents": NSNull()]
    }
    
    override init() {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        context = CGBitmapContextCreate(nil, 420, 235, 8, 1680, colorSpace, CGImageAlphaInfo.PremultipliedLast.rawValue)!
        super.init()
        self.actions = ["contents": NSNull()]
    }
    
    override func display() {
        let CGImage = CGBitmapContextCreateImage(context)
        self.contents = CGImage
    }
    
    private func setData(data: UnsafePointer<UInt32>) {
        let address = CGBitmapContextGetData(context)
        memcpy(address, data, 420 * 235 * 4)
        let cgImage = CGBitmapContextCreateImage(context)
        self.contents = cgImage
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
