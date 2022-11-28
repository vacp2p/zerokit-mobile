//
//  ContentView.swift
//  zerokit-ios
//
//  Created by Richard Ramos on 27/11/22.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text(newRLN())
        }
        .padding()
    }
}



// toBuffer converts the input to a buffer object that is used to communicate data with the rln lib
func toBuffer(data: inout [UInt8]) -> Buffer {
    let result = sliceToPtr(data: &data)
    return Buffer(
        ptr: result.dataPtr,
        len: uintptr_t(result.dataLen)
    )
}

func sliceToPtr(data: inout [UInt8]) -> (dataPtr: UnsafePointer<UInt8>?, dataLen: CInt) {
    if data.count == 0 {
        return (nil, CInt(0))
    } else {
        let uint8Pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
        uint8Pointer.initialize(from: &data, count: data.count)
        return (UnsafePointer<UInt8>(uint8Pointer), CInt(data.count))
      // return (UnsafePointer<UInt8>(data), CInt(data.count))
    }
}

func toCBufferPtr(input: inout [UInt8]) -> UnsafeMutablePointer<Buffer> {
    let buf = toBuffer(data: &input)
    let size = MemoryLayout.stride(ofValue: buf)
    let allocB = UnsafeMutablePointer<Buffer>.allocate(capacity: size)
    allocB.initialize(to: buf)
    return allocB
}

func readFile(filename: String, filetype: String) -> [UInt8] {
    do {
        let path = Bundle.main.path(forResource: filename, ofType: filetype)
        let data = try Data(contentsOf: URL(fileURLWithPath: path!))
        return Array(data)
    } catch {
        //TODO: handle error
        print(error)
    }
    return [UInt8]()
}

func createOutputBuffer() -> UnsafeMutablePointer<Buffer> {
    let size = MemoryLayout<Buffer>.stride
    return UnsafeMutablePointer<Buffer>.allocate(capacity: size)
}

func generateCredentials(ctx: OpaquePointer!) -> [UInt8] {
    // Generating credentials ======
    let credentialBuffer = createOutputBuffer()
    if key_gen(ctx, credentialBuffer) {
        let bufferPointer = UnsafeRawBufferPointer(start: credentialBuffer.pointee.ptr, count: Int(credentialBuffer.pointee.len))
        var generatedKeyBytes = [UInt8]()
        bufferPointer.withUnsafeBytes {
            generatedKeyBytes.append(contentsOf: $0)
        }
        // TODO: generatedKeyBytes will contain 64 bytes now. Extract IDCommitment and IDKey into a specific type
        
        return generatedKeyBytes
    } else {
        // TODO: throw error
    }
    
    return [UInt8]()
}

func getMerkleRoot(ctx: OpaquePointer!) -> [UInt8] {
    let rootBuffer = createOutputBuffer()
    if get_root(ctx, rootBuffer) {
        let bufferPointer = UnsafeRawBufferPointer(start: rootBuffer.pointee.ptr, count: Int(rootBuffer.pointee.len))
        var rootBytes = [UInt8]()
        bufferPointer.withUnsafeBytes {
            rootBytes.append(contentsOf: $0)
        }
        return rootBytes
    } else {
        // TODO: throw error
    }
    return [UInt8]()
}

func newRLN() -> String {
    // Reading resource files
    var circom_bytes = readFile(filename: "rln", filetype: "wasm")
    var zkey_bytes = readFile(filename: "rln_final", filetype: "zkey")
    var vk_bytes = readFile(filename: "verification_key", filetype: "json")
    
    let circom_buffer = toCBufferPtr(input: &circom_bytes)
    let zkey_buffer = toCBufferPtr(input: &zkey_bytes)
    let vk_buffer = toCBufferPtr(input: &vk_bytes)
    
    // Instantiating RLN object
    let objUnsafeMutablePtr = UnsafeMutablePointer<AnyObject>.allocate(capacity: 1)
    var ctx : OpaquePointer! = OpaquePointer(objUnsafeMutablePtr)
    if !new_with_params(20, circom_buffer, zkey_buffer, vk_buffer, &ctx) {
        // TODO: throw error
    }
    
    let newCredential = generateCredentials(ctx: ctx)
    
    let merkleRoot = getMerkleRoot(ctx: ctx)

    return "Hello World"
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
