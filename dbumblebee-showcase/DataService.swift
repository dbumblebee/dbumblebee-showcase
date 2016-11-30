//
//  DataService.swift
//  dbumblebee-showcase
//
//  Created by Brian Bresen on 11/22/16.
//  Copyright © 2016 BeeHive Productions. All rights reserved.
//

import Foundation
import Firebase
import FirebaseStorage

class DataService {
    static let ds = DataService()
    
    private var _REF_BASE = FIRDatabase.database().reference()
    
    var REF_BASE: FIRDatabaseReference {
        return _REF_BASE
    }
    
    var REF_USERS: FIRDatabaseReference {
        return REF_BASE.child("users")
    }
    
    var REF_POSTS: FIRDatabaseReference {
        return REF_BASE.child("posts")
    }
    
    var REF_USER_CURRENT: FIRDatabaseReference {
        let userID = FIRAuth.auth()?.currentUser?.uid
        let user = REF_USERS.child(userID!)
        return user
    }
    
    var REF_STORAGE: FIRStorage {
        return FIRStorage.storage()
    }
    
    func createFirebaseUser(uid: String, user: Dictionary<String,String>) {
        REF_USERS.child(uid).updateChildValues(user)
    }
}
