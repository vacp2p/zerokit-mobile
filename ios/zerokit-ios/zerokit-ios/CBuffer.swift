import Foundation

class CBuffer {
    let bufferPtr: UnsafeMutablePointer<Buffer>
    
    init(input: inout [UInt8]) {
        bufferPtr = CBuffer.toPointer(input: &input)
    }
    
    init() {
        let size = MemoryLayout<Buffer>.stride
        bufferPtr = UnsafeMutablePointer<Buffer>.allocate(capacity: size)
    }
    
    deinit {
        bufferPtr.deallocate()
    }
    
    // toBuffer converts the input to a buffer object that is used to communicate data with the rln lib
    private static func toBuffer(data: inout [UInt8]) -> Buffer {
        let result = sliceToPtr(data: &data)
        return Buffer(
            ptr: result.dataPtr,
            len: uintptr_t(result.dataLen)
        )
    }

    private static func sliceToPtr(data: inout [UInt8]) -> (dataPtr: UnsafePointer<UInt8>?, dataLen: CInt) {
        if data.count == 0 {
            return (nil, CInt(0))
        } else {
            let uint8Pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
            uint8Pointer.initialize(from: &data, count: data.count)
            return (UnsafePointer<UInt8>(uint8Pointer), CInt(data.count))
        }
    }
    
    private static func toPointer(input: inout [UInt8]) -> UnsafeMutablePointer<Buffer> {
        let buf = toBuffer(data: &input)
        let size = MemoryLayout.stride(ofValue: buf)
        let allocB = UnsafeMutablePointer<Buffer>.allocate(capacity: size)
        allocB.initialize(to: buf)
        return allocB
    }
}
