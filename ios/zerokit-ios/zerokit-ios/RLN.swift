import Foundation

enum RLNError: Error {
    case couldNotInstantiate
    case noCredentialsGenerated
    case insertFailure
    case couldNotObtainMerkleRoot
}

class RLN {
    private var ctx: OpaquePointer!
    
    init(circomBytes: [UInt8], zkeyBytes: [UInt8], vkBytes: [UInt8], depth: UInt = 20) throws {
        let circom_buffer = CBuffer(input: circomBytes)
        let zkey_buffer = CBuffer(input: zkeyBytes)
        let vk_buffer = CBuffer(input: vkBytes)
    
        // Instantiating RLN object
        let objUnsafeMutablePtr = UnsafeMutablePointer<AnyObject>.allocate(capacity: 1)
        self.ctx = OpaquePointer(objUnsafeMutablePtr)
        
        if !new_with_params(depth, circom_buffer.bufferPtr, zkey_buffer.bufferPtr, vk_buffer.bufferPtr, &ctx) {
            objUnsafeMutablePtr.deallocate()
            throw RLNError.couldNotInstantiate
        }
    }
    
    deinit {
        let ptr = UnsafeMutablePointer<AnyObject>(self.ctx)
        ptr?.deallocate()
    }
    
    func generateCredentials() throws -> MembershipKey {
        let credentialBuffer = CBuffer()
        if key_gen(self.ctx, credentialBuffer.bufferPtr) {
            let bufferPointer = UnsafeRawBufferPointer(start: credentialBuffer.bufferPtr.pointee.ptr, count: Int(credentialBuffer.bufferPtr.pointee.len))
            var generatedKeyBytes = [UInt8]()
            bufferPointer.withUnsafeBytes {
                generatedKeyBytes.append(contentsOf: $0)
            }
            return try MembershipKey.fromBytes(memKeys: generatedKeyBytes)
        }
        
        throw RLNError.noCredentialsGenerated
    }
    
    func insertMember(credential: MembershipKey) throws {
        let inputBuffer = CBuffer(input: credential.idCommitment)
        if !set_next_leaf(self.ctx, inputBuffer.bufferPtr) {
            throw RLNError.insertFailure
        }
    }

    func insertMembers(commitments: [IDCommitment], index: UInt) throws {
        var cnt = UInt64(littleEndian: UInt64(commitments.count))
        let countBytes = withUnsafeBytes(of: &cnt) { Array($0) }
        
        var credentialsBytes = countBytes
        commitments.forEach {
            credentialsBytes += $0
        }
        
        let inputBuffer = CBuffer(input: credentialsBytes)
        if !set_leaves_from(self.ctx, index, inputBuffer.bufferPtr) {
            throw RLNError.insertFailure
        }
    }
    
    func getMerkleRoot() throws -> [UInt8] {
        let output = CBuffer()
        if get_root(ctx, output.bufferPtr) {
            let bufferPointer = UnsafeRawBufferPointer(start: output.bufferPtr.pointee.ptr, count: Int(output.bufferPtr.pointee.len))
            var rootBytes = [UInt8]()
            bufferPointer.withUnsafeBytes {
                rootBytes.append(contentsOf: $0)
            }
            return rootBytes
        }
        
        throw RLNError.couldNotObtainMerkleRoot
    }
    
}
