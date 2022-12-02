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
        let rlnObj = try RLN(circom_bytes, zkey_bytes, vk_bytes)

        // Generating a credential
        let newCredential = try rlnObj.generateCredentials()
        
        // Inserting a single credential
        try rlnObj.insertMember(newCredential)
        
        // Inserting multiple credentials
        var commitmentCollection = [IDCommitment]()
        for _ in 1...3 {
            let currCred = try rlnObj.generateCredentials()
            commitmentCollection.append(currCred.idCommitment)
        }
        try rlnObj.insertMembers(commitmentCollection, 1)
        
        // Obtaining the current merkle root
        let merkleRoot = try rlnObj.getMerkleRoot()
        
        let msg: [UInt8] = [1,2,3,4,5,6,7,8,9,10]
        
        // GenerateRLNProof
        let proof = try rlnObj.generateRLNProof(msg, 0, Date(), newCredential.idKey)
        
        print("Proof generated succesfully!")
        
        // TODO: validateProof
        
    } catch {
        print("Unexpected error: \(error).")
    }
   
    return "Hello World"
    
}
