//
//  Component.swift
//  C64
//
//  Created by Fabio Ritrovato on 03/12/2015.
//  Copyright © 2015 orange in a day. All rights reserved.
//

internal protocol ComponentState: CustomStringConvertible {
    
    func toDictionary() -> [String: AnyObject]
    
}

extension ComponentState {
    
    var description: String {
        let m = Mirror(reflecting: self)
        let descriptions = m.children.map({ ($0.label ?? "_") + ": \($0.value)" })
        return "[" + descriptions.joinWithSeparator(", ") + "]"
    }
    
    func toDictionary() -> [String: AnyObject] {
        let m = Mirror(reflecting: self)
        var dictionary = [String: AnyObject]()
        for (label, value) in m.children where label != nil {
            if let value = value as? AnyObject {
                dictionary[label!] = value
            } else if let value = value as? UInt8 {
                dictionary[label!] = UInt(value)
            } else if let value = value as? UInt16 {
                dictionary[label!] = UInt(value)
            } else if let value = value as? [UInt8] {
                dictionary[label!] = value.map { UInt($0) }
            } else if let value = value as? [UInt16] {
                dictionary[label!] = value.map { UInt($0) }
            } else if let value = value as? [UInt32] {
                dictionary[label!] = value.map { UInt($0) }
            } else if let value = value as? UnsafeMutableBufferPointer<UInt32> {
                dictionary[label!] = value.map { UInt($0) }
            } else {
                fatalError("Unknown ComponentState value type \(value.dynamicType)")
            }
        }
        return dictionary
    }
    
}

internal protocol Component {
    
    func componentState() -> ComponentState
    
}
