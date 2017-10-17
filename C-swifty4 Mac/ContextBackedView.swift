//
//  ContextBackedView.swift
//  C-swifty4 Mac
//
//  Created by Fabio Ritrovato on 12/01/2015.
//  Copyright (c) 2015 orange in a day. All rights reserved.
//

import Cocoa

private class ContextBackedLayer: CALayer {

    private let size: CGSize
    private let safeArea: NSEdgeInsets
    private let context: CGContext

    required init(size: CGSize, safeArea: NSEdgeInsets) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        self.size = size
        self.safeArea = safeArea
        context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: Int(size.width) * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        super.init()
        actions = ["contents": NSNull()]
        backgroundColor = NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0).cgColor
        updateContentsRect()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    override func display() {
        let cgImage = context.makeImage()
        contents = cgImage
    }
    
    fileprivate func setData(_ data: UnsafePointer<UInt32>) {
        let address = context.data
        memcpy(address, data, Int(size.width) * Int(size.height) * 4)
        let cgImage = context.makeImage()
        contents = cgImage
    }
    
    override var bounds: CGRect {
        didSet {
            if bounds.size != oldValue.size {
                updateContentsRect()
            }
        }
    }
    
    private func updateContentsRect() {
        let safeW = size.width - safeArea.left - safeArea.right
        let safeH = size.height - safeArea.top - safeArea.bottom
        var wScale = bounds.width / safeW
        var hScale = bounds.height / safeH
        if wScale > hScale {
            wScale /= hScale
            hScale = safeH / size.height
        } else {
            hScale /= wScale
            wScale = safeW / size.width
        }
        if wScale >= 1.0 {
            wScale *= safeW / size.width
        }
        if hScale >= 1.0 {
            hScale *= safeH / size.height
        }
        let x = -wScale * 0.5 + (0.5 + ((safeArea.left - safeArea.right) / size.width) / 2.0)
        let y = -hScale * 0.5 + (0.5 + ((safeArea.bottom - safeArea.top) / size.height) / 2.0)
        contentsRect = CGRect(x: x, y: y, width: wScale, height: hScale)
    }
    
}

class ContextBackedView: NSView {
    
    func setTextureSize(_ size: CGSize, safeArea: NSEdgeInsets) {
        self.wantsLayer = true
        self.layer = ContextBackedLayer(size: size, safeArea: safeArea)
    }

    internal func setData(_ data: UnsafePointer<UInt32>) {
        let layer = self.layer as! ContextBackedLayer
        layer.setData(data)
    }
    
}
