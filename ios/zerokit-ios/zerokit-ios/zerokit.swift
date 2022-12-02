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
        
        // TODO: delete member
        // TODO: seeded_key_gen
        
        // Obtaining the current merkle root
        var merkleRoot = try rlnObj.getMerkleRoot()
        
        let msg: [UInt8] = [1,2,3,4,5,6,7,8,9,10]
        
        // Generate RLN Proof
        let proof = try rlnObj.generateRLNProof(msg, 0, Date(), newCredential.idKey)
        print("Proof generated succesfully!")
        
        // Verify RLN Proof
        let isValid = try rlnObj.verifyProof(proof, msg)
        print("Proof validated succesfully: ", isValid)
        
        // Verify RLN Proof passing window of merkle roots to validate
        let isValid2 = try rlnObj.verifyProofWithRoots(proof, msg, [merkleRoot])
        print("Proof validated succesfully: ", isValid2)
        
        
    } catch {
        print("Unexpected error: \(error).")
    }
   
    return "Hello World"
    
}
