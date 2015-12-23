//
//  Line.swift
//  C64
//
//  Created by Fabio on 23/12/2015.
//  Copyright © 2015 orange in a day. All rights reserved.
//

internal protocol LineComponent: class {
    
    var state: Bool { get }
    func lineChanged(line: Line)

}

extension LineComponent {
    
    func lineChanged(line: Line) { }
    
}

internal protocol IRQLineComponent: LineComponent {
    
    var irqPin: Bool { get }
    
}

extension IRQLineComponent {
    
    // Override for components that actively drive the line
    var irqPin: Bool {
        return true
    }
    
    var state: Bool {
        return irqPin
    }
    
}

internal final class Line {

    private(set) var state: Bool = true
    
    private var components = [LineComponent]()
    
    func addComponents(components: [LineComponent]) {
        self.components.appendContentsOf(components)
    }
    
    func update(source: LineComponent) {
        let oldState = state
        state = components.reduce(true) { return $0 && $1.state }
        if oldState != state {
            for otherComponent in components where otherComponent !== source {
                otherComponent.lineChanged(self)
            }
        }
    }
    
}
