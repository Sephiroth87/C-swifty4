//
//  ContextBackedView.swift
//  C-swifty4 Mac
//
//  Created by Fabio Ritrovato on 12/01/2015.
//  Copyright (c) 2015 orange in a day. All rights reserved.
//

import Cocoa

private class ContextBackedLayer: CALayer {

    private let size: NSSize
    private let context: CGContext

    required init(size: NSSize) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        self.size = size
        context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: Int(size.width) * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        super.init()
        self.actions = ["contents": NSNull()]
        self.backgroundColor = NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0).cgColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    override func display() {
        let CGImage = context.makeImage()
        self.contents = CGImage
    }
    
    fileprivate func setData(_ data: UnsafePointer<UInt32>) {
        let address = context.data
        memcpy(address, data, Int(size.width) * Int(size.height) * 4)
        let cgImage = context.makeImage()
        self.contents = cgImage
    }
    
    override var bounds: CGRect {
        didSet {
            var wScale = bounds.width / size.width
            var hScale = bounds.height / size.height
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

    var size: NSSize = .zero {
        didSet {
            self.wantsLayer = true
            self.layer = ContextBackedLayer(size: size)
        }
    }

    internal func setData(_ data: UnsafePointer<UInt32>) {
        let layer = self.layer as! ContextBackedLayer
        layer.setData(data)
    }
    
}
