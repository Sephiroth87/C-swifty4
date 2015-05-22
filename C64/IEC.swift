//
//  IEC.swift
//  C-swifty4
//
//  Created by Fabio Ritrovato on 20/05/2015.
//  Copyright (c) 2015 orange in a day. All rights reserved.
//

final internal class IEC {
    
    internal private(set) var atnLine = true
    internal private(set) var clkLine = true
    internal private(set) var dataLine = true
    
    internal func updateCiaPins(#atnPin: Bool, clkPin: Bool, dataPin: Bool) {
        atnLine = !atnPin
        clkLine = !clkPin
        dataLine = !dataPin
    }
    
}
