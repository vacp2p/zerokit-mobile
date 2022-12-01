import Foundation

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

func generateCredentials(ctx: OpaquePointer!) -> [UInt8] {
    // Generating credentials ======
    let credentialBuffer = CBuffer()
    if key_gen(ctx, credentialBuffer.bufferPtr) {
        let bufferPointer = UnsafeRawBufferPointer(start: credentialBuffer.bufferPtr.pointee.ptr, count: Int(credentialBuffer.bufferPtr.pointee.len))
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
    let output = CBuffer()
    if get_root(ctx, output.bufferPtr) {
        let bufferPointer = UnsafeRawBufferPointer(start: output.bufferPtr.pointee.ptr, count: Int(output.bufferPtr.pointee.len))
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
    
    let circom_buffer = CBuffer(input: &circom_bytes)
    let zkey_buffer = CBuffer(input: &zkey_bytes)
    let vk_buffer = CBuffer(input: &vk_bytes)
    
    // Instantiating RLN object
    let objUnsafeMutablePtr = UnsafeMutablePointer<AnyObject>.allocate(capacity: 1)
    var ctx : OpaquePointer! = OpaquePointer(objUnsafeMutablePtr)
    if !new_with_params(20, circom_buffer.bufferPtr, zkey_buffer.bufferPtr, vk_buffer.bufferPtr, &ctx) {
        // TODO: throw error
    }
    
    let newCredential = generateCredentials(ctx: ctx)
    
    let merkleRoot = getMerkleRoot(ctx: ctx)

    return "Hello World"
    
}
