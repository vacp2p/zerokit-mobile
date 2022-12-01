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


func insertMember(ctx: OpaquePointer!, credential: MembershipKey) throws {
    let inputBuffer = CBuffer(input: credential.idCommitment)
    if !set_next_leaf(ctx, inputBuffer.bufferPtr) {
        throw RLNError.memberNotInserted
    }
}

func insertMembers(ctx: OpaquePointer!, commitments: [IDCommitment], index: UInt) throws {
    var cnt = UInt64(littleEndian: UInt64(commitments.count))
    let countBytes = withUnsafeBytes(of: &cnt) { Array($0) }
    
    var credentialsBytes = countBytes
    commitments.forEach {
        credentialsBytes += $0
    }
    
    let inputBuffer = CBuffer(input: credentialsBytes)
    if !set_leaves_from(ctx, index, inputBuffer.bufferPtr) {
        throw RLNError.memberNotInserted
    }
}


let DefaultEpochUnitSeconds = 10; // the rln-relay epoch length in seconds

enum RLNError: Error {
    case noCredentialsGenerated
    case memberNotInserted
}


func generateCredentials(ctx: OpaquePointer!) throws -> MembershipKey {
    // Generating credentials ======
    let credentialBuffer = CBuffer()
    if key_gen(ctx, credentialBuffer.bufferPtr) {
        let bufferPointer = UnsafeRawBufferPointer(start: credentialBuffer.bufferPtr.pointee.ptr, count: Int(credentialBuffer.bufferPtr.pointee.len))
        var generatedKeyBytes = [UInt8]()
        bufferPointer.withUnsafeBytes {
            generatedKeyBytes.append(contentsOf: $0)
        }
        return try MembershipKey.fromBytes(memKeys: generatedKeyBytes)
    }
    
    throw RLNError.noCredentialsGenerated
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
    let circom_bytes = readFile(filename: "rln", filetype: "wasm")
    let zkey_bytes = readFile(filename: "rln_final", filetype: "zkey")
    let vk_bytes = readFile(filename: "verification_key", filetype: "json")
    
    let circom_buffer = CBuffer(input: circom_bytes)
    let zkey_buffer = CBuffer(input: zkey_bytes)
    let vk_buffer = CBuffer(input: vk_bytes)
    
    // Instantiating RLN object
    let objUnsafeMutablePtr = UnsafeMutablePointer<AnyObject>.allocate(capacity: 1)
    var ctx : OpaquePointer! = OpaquePointer(objUnsafeMutablePtr)
    if !new_with_params(20, circom_buffer.bufferPtr, zkey_buffer.bufferPtr, vk_buffer.bufferPtr, &ctx) {
        // TODO: throw error
    }
    
    do {
        let newCredential = try generateCredentials(ctx: ctx)
        
        try insertMember(ctx: ctx, credential: newCredential)
        
        var commitmentCollection = [IDCommitment]()
        for _ in 1...3 {
            let currCred = try generateCredentials(ctx: ctx)
            commitmentCollection.append(currCred.idCommitment)
        }
        try insertMembers(ctx: ctx, commitments: commitmentCollection, index: 1)
    } catch {
        print("Unexpected error: \(error).")
    }
    
    // TODO: Calculate Epoch
    // TODO: Serialize Message
    // TODO: generateRLNProof
    // TODO: validateProof
    
    let merkleRoot = getMerkleRoot(ctx: ctx)

    return "Hello World"
    
}
