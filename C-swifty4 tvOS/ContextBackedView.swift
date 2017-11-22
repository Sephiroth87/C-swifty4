//
//  ContextBackedView.swift
//  C-swifty4 iOS
//
//  Created by Fabio Ritrovato on 10/01/2015.
//  Copyright (c) 2015 orange in a day. All rights reserved.
//

import UIKit

private class ContextBackedLayer: CALayer {
    
    private var size: CGSize = .zero
    private var safeArea: UIEdgeInsets = .zero
    private var context: CGContext?
    
    override init() {
        super.init()
        actions = ["contents": NSNull()]
        backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0).cgColor
        updateContentsRect()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    func setTextureSize(_ size: CGSize, safeArea: UIEdgeInsets) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        self.size = size
        self.safeArea = safeArea
        context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: Int(size.width) * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        updateContentsRect()
    }
    
    override func display() {
        guard let context = context else { return }
        let cgImage = context.makeImage()
        contents = cgImage
    }
    
    fileprivate func setData(_ data: UnsafePointer<UInt32>) {
        guard let context = context else { return }
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
        let x = -wScale * 0.5 + (0.5 + ((safeArea.left + safeArea.right) / size.width) / 2.0)
        let y = -hScale * 0.5 + (0.5 + ((safeArea.bottom + safeArea.top) / size.height) / 2.0)
        contentsRect = CGRect(x: x, y: y, width: wScale, height: hScale)
    }
    
}

class ContextBackedView: UIView {
    
    override class var layerClass : AnyClass {
        return ContextBackedLayer.self
    }
    
    func setTextureSize(_ size: CGSize, safeArea: (top: Int, left: Int, bottom: Int, right: Int)) {
        let layer = self.layer as! ContextBackedLayer
        layer.setTextureSize(size, safeArea: UIEdgeInsets(top: CGFloat(safeArea.top), left: CGFloat(safeArea.left), bottom: CGFloat(safeArea.bottom), right: CGFloat(safeArea.right)))
    }

    override func draw(_ rect: CGRect) {
    }

    internal func setData(_ data: UnsafePointer<UInt32>) {
        let layer = self.layer as! ContextBackedLayer
        layer.setData(data)
    }
    
}
