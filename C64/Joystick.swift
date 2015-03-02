//
//  Joystick.swift
//  C-swifty4
//
//  Created by Fabio Ritrovato on 02/03/2015.
//  Copyright (c) 2015 orange in a day. All rights reserved.
//

public enum JoystickXAxisStatus {
    case None
    case Left
    case Right
}

public enum JoystickYAxisStatus {
    case None
    case Up
    case Down
}

final internal class Joystick {
    
    internal var xAxis: JoystickXAxisStatus = .None
    internal var yAxis: JoystickYAxisStatus = .None
    
}
