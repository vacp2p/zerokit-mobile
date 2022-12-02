import Foundation

typealias Epoch = [UInt8]

let DefaultEpochUnitSeconds = 10; // the rln-relay epoch length in seconds

func epochIntToBytes(epoch: Int) -> Epoch {
    var epoch64 = UInt64(littleEndian: UInt64(epoch))
    let epochBytes = withUnsafeBytes(of: &epoch64) { Array($0) }
    
    let padLen = 32 - (epochBytes.count % 32)
    if padLen > 0 {
      return epochBytes + Array<UInt8>(repeating: 0, count: padLen)
    }
    
    return epochBytes
}

func dateToEpoch(timestamp: Date, epochUnitSeconds: Int = DefaultEpochUnitSeconds) -> Epoch {
    let unixTimestamp = Int(timestamp.timeIntervalSince1970)
    let epoch = unixTimestamp / epochUnitSeconds
    return epochIntToBytes(epoch: epoch)
}
