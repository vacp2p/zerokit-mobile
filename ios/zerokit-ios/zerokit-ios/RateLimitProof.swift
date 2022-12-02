import Foundation

enum RateLimitProofError: Error {
    case invalidProofLength
}

struct RLNProofOffset {
    static let proof = 128
    static let root = proof + 32
    static let epoch = root + 32
    static let shareX = epoch + 32
    static let shareY = shareX + 32
    static let nullifier = shareY + 32;
    static let rlnIdentifier = nullifier + 32;
}

class RateLimitProof {
    let proof: [UInt8]
    let merkleRoot: [UInt8]
    let epoch: [UInt8]
    let shareX: [UInt8]
    let shareY: [UInt8]
    let nullifier: [UInt8]
    let rlnIdentifier: [UInt8]

    init(_ proofBytes: [UInt8]) throws {
        guard proofBytes.count == 320 else {
            throw RateLimitProofError.invalidProofLength
        }
        
        // parse the proof as proof<128> | share_y<32> | nullifier<32> | root<32> | epoch<32> | share_x<32> | rln_identifier<32>
        proof = Array(proofBytes[0..<RLNProofOffset.proof])
        merkleRoot = Array(proofBytes[RLNProofOffset.proof..<RLNProofOffset.root])
        epoch = Array(proofBytes[RLNProofOffset.root..<RLNProofOffset.epoch])
        shareX = Array(proofBytes[RLNProofOffset.epoch..<RLNProofOffset.shareX])
        shareY = Array(proofBytes[RLNProofOffset.shareX..<RLNProofOffset.shareY])
        nullifier = Array(proofBytes[RLNProofOffset.shareY..<RLNProofOffset.nullifier])
        rlnIdentifier = Array(proofBytes[RLNProofOffset.nullifier..<RLNProofOffset.rlnIdentifier])
    }
    
    // serialize converts a RateLimitProof and data to a byte seq
    // this conversion is used in the proof verification proc
    // the order of serialization is based on https://github.com/kilic/rln/blob/7ac74183f8b69b399e3bc96c1ae8ab61c026dc43/src/public.rs#L205
    // [ proof<128> | root<32> | epoch<32> | share_x<32> | share_y<32> | nullifier<32> | rln_identifier<32> | signal_len<8> | signal<var> ]
    func serialize(_ msg: [UInt8]) -> [UInt8] {
        var msgLen = UInt64(littleEndian: UInt64(msg.count))
        let msgLenBytes = withUnsafeBytes(of: &msgLen) { Array($0) }
        return proof + merkleRoot + epoch + shareX + shareY + nullifier + rlnIdentifier + msgLenBytes + msg
    }
}
