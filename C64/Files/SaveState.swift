//
//  SaveState.swift
//  C64
//
//  Created by Fabio Ritrovato on 07/06/2016.
//  Copyright © 2016 orange in a day. All rights reserved.
//

public final class SaveState {
    
    private(set) public var data: [UInt8]
    private(set) internal var cpuState: CPUState
    private(set) internal var memoryState: C64MemoryState
    private(set) internal var cia1State: CIAState
    private(set) internal var cia2State: CIAState
    private(set) internal var vicState: VICState
    
    internal init(c64: C64) {
        cpuState = c64.cpu.state
        memoryState = c64.memory.state
        cia1State = c64.cia1.state
        cia2State = c64.cia2.state
        vicState = c64.vic.state
        let states: [BinaryConvertible] = [cpuState, memoryState, cia1State, cia2State, vicState]
        data = states.flatMap { $0.dump() }
    }
    
    public init(data: [UInt8]) {
        self.data = data
        let dump = BinaryDump(data: data)
        cpuState = dump.next()
        memoryState = dump.next()
        cia1State = dump.next()
        cia2State = dump.next()
        vicState = dump.next()
    }
    
}