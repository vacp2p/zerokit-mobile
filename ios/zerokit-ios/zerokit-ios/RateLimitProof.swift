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
}
