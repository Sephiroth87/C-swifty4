//
//  VIC.swift
//  C-swifty4
//
//  Created by Fabio Ritrovato on 10/12/2014.
//  Copyright (c) 2014 orange in a day. All rights reserved.
//

import Foundation

final internal class VIC {
    
    internal weak var memory: C64Memory!
    
    //MARK: Memory
    private var ioMemory: [UInt8] = [UInt8](count: 64, repeatedValue: 0)
    private var videoMatrix: [UInt8] = [UInt8](count: 40, repeatedValue: 0)
    private var colorLine: [UInt8] = [UInt8](count: 40, repeatedValue: 0)
    private var mp: UInt8 = 0 // Sprite Pointer
    
    private let screenBuffer1 = UnsafeMutablePointer<UInt32>(calloc(512 * 512, sizeof(UInt32)))
    private let screenBuffer2 = UnsafeMutablePointer<UInt32>(calloc(512 * 512, sizeof(UInt32)))
    private var currentScreenBuffer: UnsafeMutablePointer<UInt32>
    internal var screenBuffer: UnsafeMutablePointer<UInt32> {
        get {
            return currentScreenBuffer == screenBuffer1 ? screenBuffer2 : screenBuffer1
        }
    }
    //MARK: -
    
    private var currentCycle = 1
    private var currentLine: UInt16 = 0
    
    //MARK: Internal Registers
    private var vc: UInt16 = 0
    private var vcbase: UInt16 = 0
    private var rc: UInt8 = 0
    private var vmli: UInt16 = 0
    private var displayState = false
    private var rasterX: UInt16 = 0x19C // NTSC
    private var mainBorder = false
    private var verticalBorder = false
    private var ref: UInt8 = 0
    private var mc: [UInt8] = [UInt8](count: 8, repeatedValue: 0)
    private var mcbase: [UInt8] = [UInt8](count: 8, repeatedValue: 0)
    private var yExpansion: [Bool] = [Bool](count: 8, repeatedValue: true)
    //MARK: -
    
    //MARK: Registers
    private var m_x: [UInt16] = [UInt16](count: 8, repeatedValue: 0) // X Coordinate Sprite
    private var m_y: [UInt8] = [UInt8](count: 8, repeatedValue: 0) // Y Coordinate Sprite
    private var yScroll: UInt8 = 0 // Y Scroll
    private var den = false // Display Enable
    private var bmm = false // Bit Map Mode
    private var ecm = false // Extended Color Mode
    private var mcm = false // Multi Color Mode
    private var raster: UInt16 = 0 // Raster Counter
    private var me: UInt8 = 0 // Sprite Enabled
    private var mye: UInt8 = 0 // Sprite Y Expansion
    private var vm: UInt8 = 0 // Video matrix base address
    private var cb: UInt8 = 0 // Character base address
    private var ec: UInt8 = 0 // Border Color
    private var mmc: UInt8 = 0 // Sprite Multicolor
    private var b0c: UInt8 = 0 // Background Color 0
    private var b1c: UInt8 = 0 // Background Color 1
    private var b2c: UInt8 = 0 // Background Color 2
    private var b3c: UInt8 = 0 // Background Color 3
    private var mm0: UInt8 = 0 // Sprite Multicolor 0
    private var mm1: UInt8 = 0 // Sprite Multicolor 1
    private var m_c: [UInt8] = [UInt8](count: 8, repeatedValue: 0) // Color Sprite
    //MARK: -
    
    //MARK: Graphic Sequencer
    private var graphicsSequencerData: UInt8 = 0
    private var graphicsSequencerShiftRegister: UInt8 = 0
    private var graphicsSequencerVideoMatrix: UInt8 = 0
    private var graphicsSequencerColorLine: UInt8 = 0
    //MARK: -
    
    //MARK: Sprite Sequencers
    private var spriteSequencerData: [UInt32] = [UInt32](count: 8, repeatedValue: 0)
    //MARK: -
    
    //MARK: Bus
    private var addressBus: UInt16 = 0
    private var dataBus: UInt8 = 0
    //MARK: -

    //MARK: Helpers
    private var memoryBankAddress: UInt16 = 0
    private var borderLeftComparisonValue: UInt16 = 24
    private var borderRightComparisonValue: UInt16 = 344
    private var borderTopComparisonValue: UInt16 = 51
    private var borderBottomComparisonValue: UInt16 = 251
    private var bufferPosition: Int = 0
    private var badLinesEnabled = false
    private var isBadLine = false
    private var currentSprite: UInt8 = 2
    private var spriteDma: [Bool] = [Bool](count: 8, repeatedValue: false)
    private var spriteDisplay: [Bool] = [Bool](count: 8, repeatedValue: false)
    private var anySpriteDisplaying = false
    private var spriteShiftRegisterCount: [Int] = [Int](count: 8, repeatedValue: 0)
    //MARK: -
    
    private let colors: [UInt32] = [
        UInt32(truncatingBitPattern: (0xFF101010 as UInt64)),
        UInt32(truncatingBitPattern: (0xFFFFFFFF as UInt64)),
        UInt32(truncatingBitPattern: (0xFF4040E0 as UInt64)),
        UInt32(truncatingBitPattern: (0xFFFFFF60 as UInt64)),
        UInt32(truncatingBitPattern: (0xFFE060E0 as UInt64)),
        UInt32(truncatingBitPattern: (0xFF40E040 as UInt64)),
        UInt32(truncatingBitPattern: (0xFFE04040 as UInt64)),
        UInt32(truncatingBitPattern: (0xFF40FFFF as UInt64)),
        UInt32(truncatingBitPattern: (0xFF40A0E0 as UInt64)),
        UInt32(truncatingBitPattern: (0xFF48749C as UInt64)),
        UInt32(truncatingBitPattern: (0xFFA0A0FF as UInt64)),
        UInt32(truncatingBitPattern: (0xFF545454 as UInt64)),
        UInt32(truncatingBitPattern: (0xFF888888 as UInt64)),
        UInt32(truncatingBitPattern: (0xFFA0FFA0 as UInt64)),
        UInt32(truncatingBitPattern: (0xFFFFA0A0 as UInt64)),
        UInt32(truncatingBitPattern: (0xFFC0C0C0 as UInt64)),
    ]
    
    init() {
        self.currentScreenBuffer = screenBuffer1
    }
    
    internal func readByte(position: UInt8) -> UInt8 {
        switch position {
        case 0x00, 0x02, 0x04, 0x06, 0x08, 0x0A, 0x0C, 0x0E:
            return UInt8(truncatingBitPattern: m_x[Int(position >> 1)])
        case 0x01, 0x03, 0x05, 0x07, 0x09, 0x0B, 0x0D, 0x0F:
            return m_y[Int((position - 1) >> 1)]
        case 0x10:
            let value = (m_x[0] & 0xFF00) >> 8 |
                (m_x[1] & 0xFF00) >> 7 |
                (m_x[2] & 0xFF00) >> 6 |
                (m_x[3] & 0xFF00) >> 5 |
                (m_x[4] & 0xFF00) >> 4 |
                (m_x[5] & 0xFF00) >> 3 |
                (m_x[6] & 0xFF00) >> 2 |
                (m_x[7] & 0xFF00) >> 1
            return UInt8(truncatingBitPattern: value)
        case 0x11:
            return yScroll | (den ? 0x10 : 0) | (bmm ? 0x20 : 0) | (ecm ? 0x40 : 0) | UInt8((raster & 0x100) >> 1)
        case 0x12:
            return UInt8(truncatingBitPattern: raster)
        case 0x15:
            return me
        case 0x16:
            return (mcm ? 0x10 : 0) //TODO: missing bit registers
        case 0x17:
            return mye
        case 0x18:
            return vm << 4 | cb << 1 | 0x01
        case 0x19:
            //TEMP: force NTSC timing
            return 0x70
        case 0x1C:
            return mmc
        case 0x20:
            return ec | 0xF0
        case 0x21:
            return b0c
        case 0x22:
            return b1c
        case 0x23:
            return b2c
        case 0x24:
            return b3c
        case 0x25:
            return mm0
        case 0x26:
            return mm1
        case 0x27...0x2E:
            return m_c[Int(position - 0x27)]
        default:
            return 0
        }
    }
    
    internal func writeByte(position:UInt8, byte: UInt8) {
        switch position {
        case 0x00, 0x02, 0x04, 0x06, 0x08, 0x0A, 0x0C, 0x0E:
            m_x[Int(position >> 1)] = (m_x[Int(position >> 1)] & 0xFF00) | UInt16(byte)
        case 0x01, 0x03, 0x05, 0x07, 0x09, 0x0B, 0x0D, 0x0F:
            m_y[Int((position - 1) >> 1)] = byte
        case 0x10:
            m_x[0] = UInt16(byte & 0x01) << 8 | (m_x[0] & 0x00FF)
            m_x[1] = UInt16(byte & 0x02) << 7 | (m_x[1] & 0x00FF)
            m_x[2] = UInt16(byte & 0x04) << 6 | (m_x[2] & 0x00FF)
            m_x[3] = UInt16(byte & 0x08) << 5 | (m_x[3] & 0x00FF)
            m_x[4] = UInt16(byte & 0x10) << 4 | (m_x[4] & 0x00FF)
            m_x[5] = UInt16(byte & 0x20) << 3 | (m_x[5] & 0x00FF)
            m_x[6] = UInt16(byte & 0x40) << 2 | (m_x[6] & 0x00FF)
            m_x[7] = UInt16(byte & 0x80) << 1 | (m_x[7] & 0x00FF)
        case 0x11:
            yScroll = byte & 0x07
            den = byte & 0x10 != 0
            bmm = byte & 0x20 != 0
            ecm = byte & 0x40 != 0
        case 0x15:
            me = byte
        case 0x16:
            mcm = byte & 0x10 != 0
        case 0x17:
            mye = byte
        case 0x18:
            cb = (byte & 0x0E) >> 1
            vm = (byte & 0xF0) >> 4
        case 0x1C:
            mmc = byte
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
        case 0x25:
            mm0 = byte & 0x0F
        case 0x26:
            mm1 = byte & 0x0F
        case 0x27...0x2E:
            m_c[Int(position - 0x27)] = byte & 0x0F
        default:
            break
        }
        ioMemory[Int(position)] = byte
    }
    
    internal func setMemoryBank(bankNumber: UInt8) {
        memoryBankAddress = UInt16(~bankNumber & 0x3) << 14
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
        
        // Initial cycle operations
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
            if ++raster == 263 {
                raster = 0
                bufferPosition = 0
                currentScreenBuffer = currentScreenBuffer == screenBuffer1 ? screenBuffer2 : screenBuffer1
            }
        default:
            break
        }
        
        // First half-cycle
        let cyclesPerRaster = 65 // NTSC
        if currentCycle != cyclesPerRaster {
            draw()
        }
        switch currentCycle {
        case 1, 3, 5, 7, 9:
            pAccess()
        case 2, 4, 6, 8, 10:
            if spriteDma[Int(currentSprite)] {
                sAccess(1)
            }
        case 16:
            gAccess()
            for i in 0...7 {
                if yExpansion[i] {
                    //TODO: Some stuff here if yExpansion vas cleared in cycle 15 (VIC addendum)
                    mcbase[i] = mc[i]
                }
                if mcbase[i] == 63 {
                    spriteDma[i] = false
                }
            }
        case 17...54:
            gAccess()
        case 55:
            gAccess()
            for i in 0...7 {
                if mye & UInt8(1 << i) != 0 {
                    yExpansion[i] = !yExpansion[i]
                }
            }
            fallthrough
        case 56:
            for i in 0...7 {
                if me & UInt8(1 << i) != 0 && m_y[i] == UInt8(truncatingBitPattern: raster) {
                    spriteDma[i] = true
                    mcbase[i] = 0
                    if mye & UInt8(1 << i) != 0 {
                        yExpansion[i] = false
                    }
                }
            }
        case cyclesPerRaster - 5:
            pAccess()
            for i in 0...7 {
                mc[i] = mcbase[i]
                if spriteDma[i] {
                    if m_y[i] == UInt8(truncatingBitPattern: raster) {
                        spriteDisplay[i] = true
                        anySpriteDisplaying = true
                    }
                } else {
                    spriteDisplay[i] = false
                }
            }
            if anySpriteDisplaying && spriteDisplay.indexOf(true) == nil {
                anySpriteDisplaying = false
            }
        case cyclesPerRaster - 3, cyclesPerRaster - 1:
            pAccess()
        case cyclesPerRaster - 4, cyclesPerRaster - 2, cyclesPerRaster:
            if spriteDma[Int(currentSprite)] {
                sAccess(1)
            }
        default:
            break
        }
        
        // Second half-cycle
        if currentCycle != cyclesPerRaster {
            draw()
        }
        switch currentCycle {
        case 1, 3, 5, 7, 9:
            if spriteDma[Int(currentSprite)] {
                sAccess(0)
            }
        case 2, 4, 6, 8, 10:
            if spriteDma[Int(currentSprite)] {
                sAccess(2)
            }
        case 15...54:
            cAccess()
        case cyclesPerRaster - 5, cyclesPerRaster - 3, cyclesPerRaster - 1:
            if spriteDma[Int(currentSprite)] {
                sAccess(0)
            }
        case cyclesPerRaster - 4, cyclesPerRaster - 2, cyclesPerRaster:
            if spriteDma[Int(currentSprite)] {
                sAccess(2)
            }
        default:
            break
        }

        if currentCycle++ == cyclesPerRaster {
            currentCycle = 1
        }
    }
    
    // Video matrix access
    private func cAccess() {
        if isBadLine {
            videoMatrix[Int(vmli)] = memoryAccess(UInt16(vm) << 10 &+ vc)
            colorLine[Int(vmli)] = memory.readColorRAMByte(vc) & 0x0F
        }
    }
    
    // Graphic access
    private func gAccess() {
        if displayState {
            if bmm {
                graphicsSequencerData = memoryAccess(UInt16(cb & 0x04) << 11 | vc << 3 | UInt16(rc))
            } else {
                graphicsSequencerData = memoryAccess(UInt16(cb) << 11 | (UInt16(videoMatrix[Int(vmli)]) & (ecm ? 0x3F : 0xFF)) << 3 | UInt16(rc))
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
    
    // Sprite data pointers access
    private func pAccess() {
        currentSprite = (currentSprite + 1) & 7
        mp = memoryAccess(UInt16(vm) << 10 | 0x03F8 | UInt16(currentSprite))
    }
    
    // Sprite data access
    private func sAccess(accessNumber: Int) {
        let data = memoryAccess(UInt16(mp) << 6 | UInt16(mc[Int(currentSprite)]))
        spriteSequencerData[Int(currentSprite)] |= UInt32(data) << UInt32(8 * (2 - accessNumber))
        mc[Int(currentSprite)]++
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
                if !mainBorder && !verticalBorder {
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
                if anySpriteDisplaying {
                    //TODO: z priority, expansion, collisions
                    for spriteIndex in 0...7 {
                        if spriteDisplay[spriteIndex] {
                            if m_x[spriteIndex] == rasterX {
                                spriteShiftRegisterCount[spriteIndex] = 24
                            }
                            if spriteShiftRegisterCount[spriteIndex] > 0 {
                                if mmc & UInt8(1 << spriteIndex) != 0 {
                                    switch (spriteSequencerData[spriteIndex] >> 22) & 0x03 {
                                    case 1:
                                        currentScreenBuffer[bufferPosition] = colors[Int(mm0)]
                                    case 2:
                                        currentScreenBuffer[bufferPosition] = colors[Int(m_c[spriteIndex])]
                                    case 3:
                                        currentScreenBuffer[bufferPosition] = colors[Int(mm1)]
                                    default:
                                        break
                                    }
                                    if i % 2 == 1 {
                                        spriteSequencerData[spriteIndex] <<= 2
                                        spriteShiftRegisterCount[spriteIndex] -= 2
                                    }
                                } else {
                                    if spriteSequencerData[spriteIndex] & 0x800000 != 0 {
                                        currentScreenBuffer[bufferPosition] = colors[Int(m_c[spriteIndex])]
                                    }
                                    spriteSequencerData[spriteIndex] <<= 1
                                    spriteShiftRegisterCount[spriteIndex]--
                                }
                            }
                        }
                    }
                }
                if mainBorder || verticalBorder {
                    currentScreenBuffer[bufferPosition] = colors[Int(ec)]
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
