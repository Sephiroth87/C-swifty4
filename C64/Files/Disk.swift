//
//  Disk.swift
//  C-swifty4
//
//  Created by Fabio Ritrovato on 18/11/2015.
//  Copyright © 2015 orange in a day. All rights reserved.
//

internal final class Track {
    
    private let data: [UInt8]
    let length: UInt
    
    init(data: [UInt8]) {
        self.data = data
        self.length = UInt(data.count) * 8
    }
    
    func readBit(_ offset: UInt) -> UInt8 {
        return data[Int(offset / 8)] & UInt8(0x80 >> (offset % 8)) != 0x00 ? 0x01 : 0x00
    }
    
}

let gcr: [UInt64] = [0x0A, 0x0B, 0x12, 0x13, 0x0E, 0x0F, 0x16, 0x17, 0x09, 0x19, 0x1A, 0x1B, 0x0D, 0x1D, 0x1E, 0x15]

private func encodeGCR(_ bytes: [UInt8]) -> [UInt8] {
    var encoded: UInt64 = 0
    encoded |= gcr[Int(bytes[0] >> 4)] << 35
    encoded |= gcr[Int(bytes[0] & 0x0F)] << 30
    encoded |= gcr[Int(bytes[1] >> 4)] << 25
    encoded |= gcr[Int(bytes[1] & 0x0F)] << 20
    encoded |= gcr[Int(bytes[2] >> 4)] << 15
    encoded |= gcr[Int(bytes[2] & 0x0F)] << 10
    encoded |= gcr[Int(bytes[3] >> 4)] << 5
    encoded |= gcr[Int(bytes[3] & 0x0F)]
    return [UInt8(truncatingBitPattern: encoded >> 32), UInt8(truncatingBitPattern: encoded >> 24), UInt8(truncatingBitPattern: encoded >> 16), UInt8(truncatingBitPattern: encoded >> 8), UInt8(truncatingBitPattern: encoded)]
}

internal final class Disk {
    
    static let sectorsPerTrack: [UInt8] = [0, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 19, 19, 19, 19, 19, 19, 19, 18, 18, 18, 18, 18, 18, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17]
    
    let tracksCount: Int
    let tracks: [Track]
    
    init(d64Data: UnsafeBufferPointer<UInt8>) {
        switch d64Data.count {
        case 174848:
            tracksCount = 35
        default:
            print("Unsupported d64 file")
            tracksCount = 0
        }
        var tracks = [Track]()
        tracks.append(Track(data: [])) //Track 0
        let diskIDLow = d64Data[0x16500 + 0xA2]
        let diskIDHigh = d64Data[0x16500 + 0xA3]
        var dataOffset = 0
        for trackNumber in 1...UInt8(tracksCount) {
            var trackData = [UInt8]()
            trackData.reserveCapacity(7928) // Max track size
            for sectorNumber in 0..<Disk.sectorsPerTrack[Int(trackNumber)] {
                // Header SYNC
                trackData.append(0xFF); trackData.append(0xFF); trackData.append(0xFF); trackData.append(0xFF); trackData.append(0xFF);
                // Header info
                let headerChecksum = UInt8(sectorNumber) ^ trackNumber ^ diskIDLow ^ diskIDHigh
                trackData.append(contentsOf: encodeGCR([0x08, headerChecksum, sectorNumber, trackNumber]))
                trackData.append(contentsOf: encodeGCR([diskIDLow, diskIDHigh, 0x0F, 0x0F]))
                // Header gap
                trackData.append(0x55); trackData.append(0x55); trackData.append(0x55); trackData.append(0x55); trackData.append(0x55);
                trackData.append(0x55); trackData.append(0x55); trackData.append(0x55); trackData.append(0x55);
                // Data SYNC
                trackData.append(0xFF); trackData.append(0xFF); trackData.append(0xFF); trackData.append(0xFF); trackData.append(0xFF);
                // Data block
                var dataChecksum: UInt8 = d64Data[dataOffset] ^ d64Data[dataOffset + 1] ^ d64Data[dataOffset + 2]
                trackData.append(contentsOf: encodeGCR([0x07, d64Data[dataOffset + 0], d64Data[dataOffset + 1], d64Data[dataOffset + 2]]))
                for i in stride(from: (dataOffset + 3), to: dataOffset + 255, by: 4) {
                    dataChecksum ^= d64Data[i] ^ d64Data[i+1] ^ d64Data[i+2] ^ d64Data[i+3]
                    trackData.append(contentsOf: encodeGCR([d64Data[i], d64Data[i+1], d64Data[i+2], d64Data[i+3]]))
                }
                dataChecksum ^= d64Data[dataOffset + 255]
                trackData.append(contentsOf: encodeGCR([d64Data[dataOffset + 255], dataChecksum, 0x00, 0x0]))
                // Inter-sector gap
                trackData.append(0x55); trackData.append(0x55); trackData.append(0x55); trackData.append(0x55); trackData.append(0x55);
                trackData.append(0x55); trackData.append(0x55); trackData.append(0x55); trackData.append(0x55);
                if sectorNumber % 2 == 1 {
                    if trackNumber >= 18 && trackNumber <= 24 {
                        trackData.append(0x55); trackData.append(0x55); trackData.append(0x55); trackData.append(0x55); trackData.append(0x55);
                        trackData.append(0x55); trackData.append(0x55); trackData.append(0x55); trackData.append(0x55); trackData.append(0x55);
                    } else if trackNumber >= 25 && trackNumber <= 30 {
                        trackData.append(0x55); trackData.append(0x55); trackData.append(0x55); trackData.append(0x55);
                    } else if trackNumber >= 31 {
                        trackData.append(0x55);
                    }
                }
                dataOffset += 256
            }
            tracks.append(Track(data: trackData))
        }
        self.tracks = tracks
    }
    
}
