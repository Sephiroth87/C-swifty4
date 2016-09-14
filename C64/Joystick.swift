//
//  Joystick.swift
//  C-swifty4
//
//  Created by Fabio Ritrovato on 02/03/2015.
//  Copyright (c) 2015 orange in a day. All rights reserved.
//

public enum JoystickXAxisStatus {
    case none
    case left
    case right
}

public enum JoystickYAxisStatus {
    case none
    case up
    case down
}

public enum JoystickButtonStatus {
    case released
    case pressed
}

final internal class Joystick {
    
    internal var xAxis: JoystickXAxisStatus = .none
    internal var yAxis: JoystickYAxisStatus = .none
    internal var button: JoystickButtonStatus = .released
    
}
