//
//  Line.swift
//  C64
//
//  Created by Fabio on 23/12/2015.
//  Copyright © 2015 orange in a day. All rights reserved.
//

internal protocol LineComponent: class {
    
    func pin(_ line: Line) -> Bool
    func lineChanged(_ line: Line)

}

extension LineComponent {
    
    func pin(_ line: Line) -> Bool { return true }
    func lineChanged(_ line: Line) { }
    
}

internal final class Line {

    private(set) var state: Bool = true
    
    private var components = [LineComponent]()
    
    func addComponents(_ components: [LineComponent]) {
        self.components.append(contentsOf: components)
    }
    
    func update(_ source: LineComponent) {
        let oldState = state
        state = components.reduce(true) { return $0 && $1.pin(self) }
        if oldState != state {
            for otherComponent in components where otherComponent !== source {
                otherComponent.lineChanged(self)
            }
        }
    }
    
}
