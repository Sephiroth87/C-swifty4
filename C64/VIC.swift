//
//  VIC.swift
//  C-swifty4
//
//  Created by Fabio Ritrovato on 10/12/2014.
//  Copyright (c) 2014 orange in a day. All rights reserved.
//

import Foundation

final internal class VIC {
    
    internal weak var memory: Memory!
    
    //MARK: Memory
    private var ioMemory: [UInt8] = [UInt8](count: 64, repeatedValue: 0)
    private var videoMatrix: [UInt8] = [UInt8](count: 40, repeatedValue: 0)
    private var colorLine: [UInt8] = [UInt8](count: 40, repeatedValue: 0)
    
    private let screenBuffer1 = UnsafeMutablePointer<UInt32>(calloc(512 * 512, UInt(sizeof(UInt32))))
    private let screenBuffer2 = UnsafeMutablePointer<UInt32>(calloc(512 * 512, UInt(sizeof(UInt32))))
    private var currentScreenBuffer: UnsafeMutablePointer<UInt32>
    internal var screenBuffer: UnsafeMutablePointer<UInt32> {
        get {
            return currentScreenBuffer == screenBuffer1 ? screenBuffer2 : screenBuffer1
        }
    }
    //MARK: -
    
    private var currentCycle = 1
    private var currentLine: UInt16 = 0
    
    //MARK: Registers
    private var vc: UInt16 = 0
    private var vcbase: UInt16 = 0
    private var rc: UInt8 = 0
    private var vmli: UInt16 = 0
    private var displayState = false
    private var raster: UInt16 = 0
    private var rasterX: Int = 0x19C // NTSC
    private var mainBorder = false
    private var verticalBorder = false
    private var ref: UInt8 = 0
    //MARK: -
    
    //MARK: Memory Registers Helpers
    private var yScroll: UInt8 = 0 // Y Scroll
    private var den = false // Display Enable
    private var bmm = false // Bit Map Mode
    private var ecm = false // Extended Color Mode
    private var mcm = false // Multi Color Mode
    private var cb13cb12cb11: UInt8 = 0 // Character base address
    private var ec: UInt8 = 0 // Border Color
    private var b0c: UInt8 = 0 // Background Color 0
    private var b1c: UInt8 = 0 // Background Color 1
    private var b2c: UInt8 = 0 // Background Color 2
    private var b3c: UInt8 = 0 // Background Color 3
    //MARK: -
    
    //MARK: Graphic Sequencer
    private var graphicsSequencerData: UInt8 = 0
    private var graphicsSequencerShiftRegister: UInt8 = 0
    private var graphicsSequencerVideoMatrix: UInt8 = 0
    private var graphicsSequencerColorLine: UInt8 = 0
    //MARK: -
    
    //MARK: Bus
    private var addressBus: UInt16 = 0
    private var dataBus: UInt8 = 0
    //MARK: -

    //MARK: Helpers
    private var memoryBankAddress: UInt16 = 0
    private var screenMemoryAddress: UInt16 = 0
    private var borderLeftComparisonValue: Int = 24
    private var borderRightComparisonValue: Int = 344
    private var borderTopComparisonValue: UInt16 = 51
    private var borderBottomComparisonValue: UInt16 = 251
    private var bufferPosition: Int = 0
    private var badLinesEnabled = false
    private var isBadLine = false
    //MARK: -
    
    private let colors: [UInt32] = [
        UInt32(bitPattern: Int32(truncatingBitPattern: 0xFF101010)),
        UInt32(bitPattern: Int32(truncatingBitPattern: 0xFFFFFFFF)),
        UInt32(bitPattern: Int32(truncatingBitPattern: 0xFF4040E0)),
        UInt32(bitPattern: Int32(truncatingBitPattern: 0xFFFFFF60)),
        UInt32(bitPattern: Int32(truncatingBitPattern: 0xFFE060E0)),
        UInt32(bitPattern: Int32(truncatingBitPattern: 0xFF40E040)),
        UInt32(bitPattern: Int32(truncatingBitPattern: 0xFFE04040)),
        UInt32(bitPattern: Int32(truncatingBitPattern: 0xFF40FFFF)),
        UInt32(bitPattern: Int32(truncatingBitPattern: 0xFF40A0E0)),
        UInt32(bitPattern: Int32(truncatingBitPattern: 0xFF48749C)),
        UInt32(bitPattern: Int32(truncatingBitPattern: 0xFFA0A0FF)),
        UInt32(bitPattern: Int32(truncatingBitPattern: 0xFF545454)),
        UInt32(bitPattern: Int32(truncatingBitPattern: 0xFF888888)),
        UInt32(bitPattern: Int32(truncatingBitPattern: 0xFFA0FFA0)),
        UInt32(bitPattern: Int32(truncatingBitPattern: 0xFFFFA0A0)),
        UInt32(bitPattern: Int32(truncatingBitPattern: 0xFFC0C0C0)),
    ]
    
    init() {
        self.currentScreenBuffer = screenBuffer1
    }
    
    internal func readByte(position: UInt8) -> UInt8 {
        switch position {
        case 0x11:
            return yScroll | (den ? 0x10 : 0) | (bmm ? 0x20 : 0) | (ecm ? 0x40 : 0) | UInt8((raster & 0x100) >> 1)
        case 0x12:
            return UInt8(truncatingBitPattern: raster)
        case 0x16:
            return (mcm ? 0x10 : 0) //TODO: missing bit registers
        case 0x19:
            //TEMP: force NTSC timing
            return 0x70
        case 0x20:
            return ec | 0xF0
        default:
            return 0
        }
    }
    
    internal func writeByte(position:UInt8, byte: UInt8) {
        switch position {
        case 0x11:
            yScroll = byte & 0x07
            den = byte & 0x10 != 0
            bmm = byte & 0x20 != 0
            ecm = byte & 0x40 != 0
        case 0x16:
            mcm = byte & 0x10 != 0
        case 0x18:
            ioMemory[Int(position)] = byte | 0x01
            cb13cb12cb11 = (byte & 0x0E) >> 1
            screenMemoryAddress = UInt16(byte & 0xF0) << 6
            return
        case 0x20:
            ec = byte & 0x0F
        case 0x21:
            b0c = byte & 0x0F
        case 0x22:
            b1c = byte & 0x0F
        case 0x23:
            b2c = byte & 0x0F
        case 0x24:
            b3c = byte & 0x0F
        default:
            break
        }
        ioMemory[Int(position)] = byte
    }
    
    internal func setMemoryBank(bankNumber: UInt8) {
        memoryBankAddress = UInt16(~bankNumber & 0x3) << 14
        cb13cb12cb11 = (ioMemory[0x18] & 0x0E) >> 1 //TODO: still needed?
        screenMemoryAddress = UInt16(ioMemory[0x18] & 0xF0) << 6
    }

    private func memoryAccess(position: UInt16) -> UInt8 {
        addressBus = memoryBankAddress &+ position
        if addressBus & 0x7000 == 0x1000 { // address in 0x1000...0x1FFF or 0x9000...0x9FFF
            // Read from character ROM
            dataBus = memory.readROMByte(0xC000 &+ position)
        } else {
            dataBus = memory.readRAMByte(addressBus)
        }
        return dataBus
    }
    
    internal func cycle() {
        if raster >= 0x30 && raster <= 0xF7 {
            if currentCycle == 1 {
                isBadLine = false
            }
            if raster == 0x30 && den {
                badLinesEnabled = true
            }
            if UInt8(raster) & 7 == yScroll && badLinesEnabled {
                isBadLine = true
                displayState = true
            }
        }
        
        switch currentCycle {
        case 1:
            if raster == 0 {
                vcbase = 0
                ref = 0xFF
            }
        case 14:
            vc = vcbase
            vmli = 0
            if isBadLine {
                rc = 0
            }
            rAccess()
        case 11...15:
            rAccess()
        case 58:
            if rc == 7 {
                displayState = false
                vcbase = vc
            }
            if displayState {
                rc = (rc + 1) & 7
            }
        case 63:
            if raster == borderBottomComparisonValue {
                verticalBorder = true
            } else if raster == borderTopComparisonValue && den {
                verticalBorder = false
            }
        case 65:
            currentCycle = 1
            if ++raster == 263 {
                raster = 0
                bufferPosition = 0
                currentScreenBuffer = currentScreenBuffer == screenBuffer1 ? screenBuffer2 : screenBuffer1
            }
            return
        default:
            break
        }
        draw()
        if currentCycle >= 16 && currentCycle <= 55 {
            gAccess()
        }
        draw()
        if currentCycle >= 15 && currentCycle <= 54 {
            cAccess()
        }
        ++currentCycle
    }
    
    // Video matrix access
    private func cAccess() {
        if isBadLine {
            videoMatrix[Int(vmli)] = memoryAccess(screenMemoryAddress &+ vc)
            colorLine[Int(vmli)] = memory.readColorRAMByte(vc) & 0x0F
        }
    }
    
    // Graphic access
    private func gAccess() {
        if displayState {
            if bmm {
                graphicsSequencerData = memoryAccess(UInt16(cb13cb12cb11 & 0x04) << 11 | vc << 3 | UInt16(rc))
            } else {
                graphicsSequencerData = memoryAccess(UInt16(cb13cb12cb11) << 11 | (UInt16(videoMatrix[Int(vmli)]) & (ecm ? 0x3F : 0xFF)) << 3 | UInt16(rc))
            }
            graphicsSequencerShiftRegister = graphicsSequencerData
            graphicsSequencerVideoMatrix = videoMatrix[Int(vmli)]
            graphicsSequencerColorLine = colorLine[Int(vmli)]
            vc = (vc + 1) & 0x3FF
            vmli = (vmli + 1) & 0x3F
        } else {
            //TODO: something here
        }
    }
    
    // DRAM refresh
    private func rAccess() {
        memoryAccess(0x3F00 | UInt16(ref))
        ref = ref &- 1
    }
    
    // Draw 4 pixels (half cycle)
    private func draw() {
        for i in 0...3 {
            if (rasterX >= 0x1E8 || rasterX < 0x18C) && raster >= 28 { // 0x1E8 first visible X coord. 0x18C last visible NTSC
                if mainBorder || verticalBorder {
                    currentScreenBuffer[bufferPosition] = colors[Int(ec)]
                } else {
                    if (!mcm && !bmm) || (mcm && graphicsSequencerColorLine & 0x08 == 0) {
                        if graphicsSequencerShiftRegister >> 7 != 0 {
                            currentScreenBuffer[bufferPosition] = colors[Int(graphicsSequencerColorLine)]
                        } else {
                            if ecm {
                                switch (graphicsSequencerVideoMatrix & 0xC0) >> 6 {
                                case 0:
                                    currentScreenBuffer[bufferPosition] = colors[Int(b0c)]
                                case 1:
                                    currentScreenBuffer[bufferPosition] = colors[Int(b1c)]
                                case 2:
                                    currentScreenBuffer[bufferPosition] = colors[Int(b2c)]
                                case 3:
                                    currentScreenBuffer[bufferPosition] = colors[Int(b3c)]
                                default:
                                    break
                                }
                            } else {
                                currentScreenBuffer[bufferPosition] = colors[Int(b0c)]
                            }
                        }
                        graphicsSequencerShiftRegister <<= 1
                    } else if bmm {
                        if mcm {
                            switch (graphicsSequencerShiftRegister & 0xC0) >> 6 {
                            case 0:
                                currentScreenBuffer[bufferPosition] = colors[Int(b0c)]
                            case 1:
                                currentScreenBuffer[bufferPosition] = colors[Int((graphicsSequencerVideoMatrix & 0xF0) >> 4)]
                            case 2:
                                currentScreenBuffer[bufferPosition] = colors[Int(graphicsSequencerVideoMatrix & 0x0F)]
                            case 3:
                                currentScreenBuffer[bufferPosition] = colors[Int(graphicsSequencerColorLine)]
                            default:
                                break
                            }
                            if i % 2 == 1 {
                                graphicsSequencerShiftRegister <<= 2
                            }
                        } else {
                            if graphicsSequencerShiftRegister >> 7 != 0 {
                                currentScreenBuffer[bufferPosition] = colors[Int((graphicsSequencerVideoMatrix & 0xF0) >> 4)]
                            } else {
                                currentScreenBuffer[bufferPosition] = colors[Int(graphicsSequencerVideoMatrix & 0x0F)]
                            }
                            graphicsSequencerShiftRegister <<= 1
                        }
                    } else {
                        switch (graphicsSequencerShiftRegister & 0xC0) >> 6 {
                        case 0:
                            currentScreenBuffer[bufferPosition] = colors[Int(b0c)]
                        case 1:
                            currentScreenBuffer[bufferPosition] = colors[Int(b1c)]
                        case 2:
                            currentScreenBuffer[bufferPosition] = colors[Int(b2c)]
                        case 3:
                            currentScreenBuffer[bufferPosition] = colors[Int(graphicsSequencerColorLine) & 0x07]
                        default:
                            break
                        }
                        if i % 2 == 1 {
                            graphicsSequencerShiftRegister <<= 2
                        }
                    }

                }
                ++bufferPosition
            }
        
            if ++rasterX == 0x200 {
                rasterX = 0
            }
            
            if rasterX == borderRightComparisonValue {
                mainBorder = true
            } else if rasterX == borderLeftComparisonValue {
                if raster == borderBottomComparisonValue {
                    verticalBorder = true
                } else if raster == borderTopComparisonValue && den {
                    verticalBorder = false
                }
                if !verticalBorder {
                    mainBorder = false
                }
            }
        }
    }
    
}
