import Foundation

enum RLNError: Error {
    case couldNotInstantiate
    case noCredentialsGenerated
    case insertFailure
    case couldNotObtainMerkleRoot
    case invalidIdKey
    case invalidIndex
    case proofGenerationFailed
}

class RLN {
    private var ctx: OpaquePointer!
    
    init(_ circomBytes: [UInt8], _ zkeyBytes: [UInt8], _ vkBytes: [UInt8], _ depth: UInt = 20) throws {
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
    
    func insertMember(_ credential: MembershipKey) throws {
        let inputBuffer = CBuffer(input: credential.idCommitment)
        if !set_next_leaf(self.ctx, inputBuffer.bufferPtr) {
            throw RLNError.insertFailure
        }
    }

    func insertMembers(_ commitments: [IDCommitment], _ index: UInt) throws {
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
    
    private func serializeMsg(_ uint8Msg: [UInt8], _ index: Int, _ epoch: Epoch, _ idKey: IDKey) -> [UInt8] {
        // calculate message length
        var msgLen64 = UInt64(littleEndian: UInt64(uint8Msg.count))
        let msgLenBytes = withUnsafeBytes(of: &msgLen64) { Array($0) }
        
        // Converting index to LE bytes
        var memIndex64 = UInt64(littleEndian: UInt64(index))
        let memIndexBytes = withUnsafeBytes(of: &memIndex64) { Array($0) }
        
        // [ id_key<32> | id_index<8> | epoch<32> | signal_len<8> | signal<var> ]
        return idKey + memIndexBytes + epoch + msgLenBytes + uint8Msg
    }
    
    func generateRLNProof(_ msg: [UInt8], _ index: Int, _ epoch: Date, _ idKey: IDKey) throws -> RateLimitProof {
        guard idKey.count == 32 else {
            throw RLNError.invalidIdKey
        }
        
        guard index >= 0 else {
            throw RLNError.invalidIndex
        }
        
        let serialized_msg = self.serializeMsg(msg, index, dateToEpoch(epoch), idKey)
        
        let input = CBuffer(input: serialized_msg)
        let output = CBuffer()
        if generate_rln_proof(self.ctx, input.bufferPtr, output.bufferPtr) {
            let bufferPointer = UnsafeRawBufferPointer(start: output.bufferPtr.pointee.ptr, count: Int(output.bufferPtr.pointee.len))
            var proofBytes = [UInt8]()
            bufferPointer.withUnsafeBytes {
                proofBytes.append(contentsOf: $0)
            }
            return try RateLimitProof(proofBytes)
        }
        
        throw RLNError.proofGenerationFailed
      }
}
