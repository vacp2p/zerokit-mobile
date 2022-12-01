import Foundation

enum MembershipKeyError: Error {
    case invalidInputLength
    case invalidIdKey
    case invalidIdCommitment
}

typealias IDKey = [UInt8]
typealias IDCommitment = [UInt8]

class MembershipKey {
    let idKey: IDKey
    let idCommitment: IDCommitment
    
    init(idKey: [UInt8], idCommitment: [UInt8]) throws {
        guard idKey.count == 32 else {
            throw MembershipKeyError.invalidIdKey
        }
        
        guard idCommitment.count == 32 else {
            throw MembershipKeyError.invalidIdCommitment
        }
        
        self.idKey = idKey
        self.idCommitment = idCommitment
    }
    
    static func fromBytes(memKeys: [UInt8]) throws -> MembershipKey {
        guard memKeys.count == 64 else {
            throw MembershipKeyError.invalidInputLength
        }
        let idKey = memKeys[0..<32]
        let idCommitment = memKeys[32...]
        return try MembershipKey(idKey: Array(idKey), idCommitment: Array(idCommitment))
     }
}
