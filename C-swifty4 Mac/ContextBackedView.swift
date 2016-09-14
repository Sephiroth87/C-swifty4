//
//  ContextBackedView.swift
//  C-swifty4 Mac
//
//  Created by Fabio Ritrovato on 12/01/2015.
//  Copyright (c) 2015 orange in a day. All rights reserved.
//

import Cocoa

private class ContextBackedLayer: CALayer {
    
    private var context: CGContext
    
    required init?(coder aDecoder: NSCoder) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        context = CGContext(data: nil, width: 418, height: 235, bitsPerComponent: 8, bytesPerRow: 418 * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        super.init(coder: aDecoder)
        self.actions = ["contents": NSNull()]
        self.backgroundColor = NSColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor
    }
    
    override init() {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        context = CGContext(data: nil, width: 418, height: 235, bitsPerComponent: 8, bytesPerRow: 418 * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        super.init()
        self.actions = ["contents": NSNull()]
        self.backgroundColor = NSColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor
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
    
    internal func setData(_ data: UnsafePointer<UInt32>) {
        let layer = self.layer as! ContextBackedLayer
        layer.setData(data)
    }
    
}
