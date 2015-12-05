//
//  Component.swift
//  C64
//
//  Created by Fabio Ritrovato on 03/12/2015.
//  Copyright © 2015 orange in a day. All rights reserved.
//

internal protocol ComponentState: CustomStringConvertible { }

extension ComponentState {
    
    var description: String {
        let m = Mirror(reflecting: self)
        return m.children.flatMap({ $0 }).description
    }
    
}

internal protocol Component {
    
    func componentState() -> ComponentState
    
}
