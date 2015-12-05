//
//  CircularBuffer.swift
//  C64
//
//  Created by Fabio Ritrovato on 30/11/2015.
//  Copyright © 2015 orange in a day. All rights reserved.
//

import Foundation

public final class CircularBuffer<T: CustomStringConvertible> {
    
    private var buffer: Array<T?>
    private var index = 0
    
    public init(capacity: Int) {
        self.buffer = Array<T?>(count: capacity, repeatedValue: nil)
    }
    
    public func add(item: T) {
        index = (index + 1) % buffer.count
        buffer[index] = item
    }
    
}

extension CircularBuffer: SequenceType {
    
    public func generate() -> AnyGenerator<T> {
        var index = self.index
        return anyGenerator({ () -> T? in
            if --index == self.index {
                return nil
            } else {
                if index == -1 {
                    index = self.buffer.count - 1
                }
                return self.buffer[index]
            }
        })
    }
    
}

extension CircularBuffer: CustomStringConvertible {
    
    public var description: String {
        get {
            return self.reduce("") { $0 + $1.description + "\n" }
        }
    }
    
}
