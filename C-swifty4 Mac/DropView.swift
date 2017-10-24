//
//  DropView.swift
//  C-swifty4 Mac
//
//  Created by Fabio on 23/10/2017.
//  Copyright © 2017 orange in a day. All rights reserved.
//

import Cocoa
import C64

class DropView: NSView {
    
    var handleFile: ((URL) -> Bool)?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        registerForDraggedTypes([NSPasteboard.PasteboardType(kUTTypeFileURL as String)])
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if let path = sender.draggingPasteboard().propertyList(forType: NSPasteboard.PasteboardType(kUTTypeFileURL as String)) as? String, let url = URL(string: path) {
            return C64.supportedFileTypes.contains(url.pathExtension) ? .copy : NSDragOperation()
        }
        return NSDragOperation()
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        if let path = sender.draggingPasteboard().propertyList(forType: NSPasteboard.PasteboardType(kUTTypeFileURL as String)) as? String, let url = URL(string: path) {
            if C64.supportedFileTypes.contains(url.pathExtension) {
                return handleFile?(url) ?? false
            }
        }
        return false
    }
    
}
