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



let DefaultEpochUnitSeconds = 10; // the rln-relay epoch length in seconds


func test() -> String {
    // Reading resource files
    let circom_bytes = readFile(filename: "rln", filetype: "wasm")
    let zkey_bytes = readFile(filename: "rln_final", filetype: "zkey")
    let vk_bytes = readFile(filename: "verification_key", filetype: "json")
    
    
    do {
        let rlnObj = try RLN(circomBytes: circom_bytes, zkeyBytes: zkey_bytes, vkBytes: vk_bytes)

        let newCredential = try rlnObj.generateCredentials()
        
        try rlnObj.insertMember(credential: newCredential)
        
        var commitmentCollection = [IDCommitment]()
        for _ in 1...3 {
            let currCred = try rlnObj.generateCredentials()
            commitmentCollection.append(currCred.idCommitment)
        }
        try rlnObj.insertMembers(commitments: commitmentCollection, index: 1)
        
        let merkleRoot = try rlnObj.getMerkleRoot()
        
        // TODO: Calculate Epoch
        // TODO: Serialize Message
        // TODO: generateRLNProof
        // TODO: validateProof
    } catch {
        print("Unexpected error: \(error).")
    }
   
    return "Hello World"
    
}
