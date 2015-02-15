//
//  ContextBackedView.swift
//  C-swifty4 Mac
//
//  Created by Fabio Ritrovato on 12/01/2015.
//  Copyright (c) 2015 orange in a day. All rights reserved.
//

import Cocoa

private class ContextBackedLayer: CALayer {
    
    private var context: CGContextRef
    
    required init(coder aDecoder: NSCoder) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        context = CGBitmapContextCreate(nil, 420, 235, 8, 1680, colorSpace, CGBitmapInfo(CGImageAlphaInfo.PremultipliedLast.rawValue))
        super.init(coder: aDecoder)
        self.actions = ["contents": NSNull()]
        self.backgroundColor = NSColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).CGColor
    }
    
    override init() {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        context = CGBitmapContextCreate(nil, 420, 235, 8, 1680, colorSpace, CGBitmapInfo(CGImageAlphaInfo.PremultipliedLast.rawValue))
        super.init()
        self.actions = ["contents": NSNull()]
        self.backgroundColor = NSColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).CGColor
    }
    
    override func display() {
        var CGImage = CGBitmapContextCreateImage(context)
        self.contents = CGImage
    }
    
    private func setData(data: UnsafePointer<UInt32>) {
        let address = CGBitmapContextGetData(context)
        memcpy(address, data, 420 * 235 * 4)
        let cgImage = CGBitmapContextCreateImage(context)
        self.contents = cgImage
    }
    
}

class ContextBackedView: NSView {

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.layer = ContextBackedLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.wantsLayer = true
        self.layer = ContextBackedLayer()
    }
    
    internal func setData(data: UnsafePointer<UInt32>) {
        let layer = self.layer as! ContextBackedLayer
        layer.setData(data)
    }
    
}
