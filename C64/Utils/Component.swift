//
//  Component.swift
//  C64
//
//  Created by Fabio Ritrovato on 03/12/2015.
//  Copyright © 2015 orange in a day. All rights reserved.
//

internal protocol ComponentState: BinaryConvertible, CustomStringConvertible {
}

extension ComponentState {
    
    var description: String {
        let m = Mirror(reflecting: self)
        let descriptions = m.children.map({ ($0.label ?? "_") + ": \($0.value)" })
        return "[" + descriptions.joinWithSeparator(", ") + "]"
    }
    
}

internal protocol Component: class {
    
    associatedtype StateType: ComponentState
    var state: StateType { get set }
    
}
