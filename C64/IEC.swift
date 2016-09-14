//
//  IEC.swift
//  C-swifty4
//
//  Created by Fabio Ritrovato on 20/05/2015.
//  Copyright (c) 2015 orange in a day. All rights reserved.
//

internal protocol IECDevice: class {
    var atnPin: Bool? { get }
    var clkPin: Bool { get }
    var dataPin: Bool { get }
    func iecUpdatedLines(atnLineUpdated: Bool, clkLineUpdated: Bool, dataLineUpdated: Bool)
}

final internal class IEC {
    
    internal private(set) var atnLine = true
    internal private(set) var clkLine = true
    internal private(set) var dataLine = true
    private var devices = [IECDevice]()
    
    func connectDevice(_ device: IECDevice) {
        devices.append(device)
    }

    internal func updatePins(_ device: IECDevice) {
        let oldAtnLine = atnLine
        let oldClkLine = clkLine
        let oldDataLine = dataLine
        atnLine = devices.reduce(true) { return $0 && $1.atnPin ?? true }
        clkLine = devices.reduce(true) { return $0 && $1.clkPin }
        dataLine = devices.reduce(true) { return $0 && $1.dataPin }
        for otherDevice in devices {
            if otherDevice !== device {
                otherDevice.iecUpdatedLines(atnLineUpdated: oldAtnLine != atnLine, clkLineUpdated: oldClkLine != clkLine, dataLineUpdated: oldDataLine != dataLine)
            }
        }
    }
    
}
