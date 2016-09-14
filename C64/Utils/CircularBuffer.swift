//
//  CircularBuffer.swift
//  C64
//
//  Created by Fabio Ritrovato on 30/11/2015.
//  Copyright © 2015 orange in a day. All rights reserved.
//

import Foundation

public final class CircularBuffer<T: CustomStringConvertible> {
    
    fileprivate var buffer: Array<T?>
    fileprivate var index = 0
    
    public init(capacity: Int) {
        self.buffer = Array<T?>(repeating: nil, count: capacity)
    }
    
    public func add(_ item: T) {
        index = (index + 1) % buffer.count
        buffer[index] = item
    }
    
}

extension CircularBuffer: Sequence {
    
    public func makeIterator() -> AnyIterator<T> {
        var index = self.index
        return AnyIterator {
            if index - 1 == self.index {
                return nil
            } else {
                let value = self.buffer[index]
                index -= 1
                if index == -1 {
                    index = self.buffer.count - 1
                }
                return value
            }
        }
    }
    
}

extension CircularBuffer: CustomStringConvertible {
    
    public var description: String {
        get {
            return self.reduce("") { $0 + $1.description + "\n" }
        }
    }
    
}
