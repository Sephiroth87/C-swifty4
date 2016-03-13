//
//  Line.swift
//  C64
//
//  Created by Fabio on 23/12/2015.
//  Copyright © 2015 orange in a day. All rights reserved.
//

internal protocol LineComponent: class {
    
    func pin(line: Line) -> Bool
    func lineChanged(line: Line)

}

extension LineComponent {
    
    func pin(line: Line) -> Bool { return true }
    func lineChanged(line: Line) { }
    
}

internal final class Line {

    private(set) var state: Bool = true
    
    private var components = [LineComponent]()
    
    func addComponents(components: [LineComponent]) {
        self.components.appendContentsOf(components)
    }
    
    func update(source: LineComponent) {
        let oldState = state
        state = components.reduce(true) { return $0 && $1.pin(self) }
        if oldState != state {
            for otherComponent in components where otherComponent !== source {
                otherComponent.lineChanged(self)
            }
        }
    }
    
}
