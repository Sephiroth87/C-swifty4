//
//  C1541.swift
//  C-swifty4
//
//  Created by Fabio Ritrovato on 17/04/2015.
//  Copyright (c) 2015 orange in a day. All rights reserved.
//

import Foundation

public protocol C1541Delegate: class {
    func C1541UpdateLedStatus(c1541: C1541, ledOn: Bool)
}

final public class C1541 {
    
    public weak var delegate: C1541Delegate?
    internal var crashHandler: C64CrashHandler? {
        didSet {
            self.cpu.crashHandler = crashHandler
        }
    }
    
    private let cpu: CPU
    private let memory: C1541Memory
    private let via1: VIA1
    private let via2: VIA2
    
    internal init(c1541Data: NSData) {
        self.cpu = CPU(pc: 0xEAA0)
        self.memory = C1541Memory()
        self.via1 = VIA1()
        self.via2 = VIA2()
        
        self.cpu.memory = self.memory
        self.memory.via1 = self.via1
        self.memory.via2 = self.via2
        self.via1.c1541 = self
        self.via1.cpu = self.cpu
        self.via2.c1541 = self
        self.via2.cpu = self.cpu
        
        self.memory.writeC1541Data(UnsafePointer<UInt8>(c1541Data.bytes))
    }
    
    internal func cycle() {
        via1.cycle()
        via2.cycle()
        cpu.executeInstruction()
    }
    
    internal func updateLedStatus(ledOn: Bool) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            let _ = self.delegate?.C1541UpdateLedStatus(self, ledOn: ledOn)
        })
    }
    
}
