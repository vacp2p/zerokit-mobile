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


func test() -> String {
    // Reading resource files
    let circom_bytes = readFile(filename: "rln", filetype: "wasm")
    let zkey_bytes = readFile(filename: "rln_final", filetype: "zkey")
    let vk_bytes = readFile(filename: "verification_key", filetype: "json")
    
    do {
        // Instantiating RLN object
        let rlnObj = try RLN(circomBytes: circom_bytes, zkeyBytes: zkey_bytes, vkBytes: vk_bytes)

        // Generating a credential
        let newCredential = try rlnObj.generateCredentials()
        
        // Inserting a single credential
        try rlnObj.insertMember(credential: newCredential)
        
        // Inserting multiple credentials
        var commitmentCollection = [IDCommitment]()
        for _ in 1...3 {
            let currCred = try rlnObj.generateCredentials()
            commitmentCollection.append(currCred.idCommitment)
        }
        try rlnObj.insertMembers(commitments: commitmentCollection, index: 1)
        
        // Obtaining the current merkle root
        let merkleRoot = try rlnObj.getMerkleRoot()
        
        // Date to epoch conversion
        let epoch = dateToEpoch(timestamp: Date())
        
        // Serialize Message
        let msg: [UInt8] = [1,2,3,4,5,6,7,8,9,10]
        let serializedMessage = rlnObj.serializeMsg(uint8Msg: msg, memIndex: 0, epoch: epoch, idKey: newCredential.idKey)
        
        // TODO: generateRLNProof
        // TODO: validateProof
    } catch {
        print("Unexpected error: \(error).")
    }
   
    return "Hello World"
    
}
