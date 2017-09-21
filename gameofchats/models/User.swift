//
//  User.swift
//  gameofchats
//
//  Created by Hoan Tran on 9/20/17.
//  Copyright © 2017 Pego Consulting. All rights reserved.
//

import UIKit
import Firebase

class User: NSObject {
    @objc var name: String?
    @objc var email: String?
    @objc var profileImageURL: String?
    
    init?(_ snapshot: DataSnapshot) {
        guard let dictionary = snapshot.value as? [String: Any] else { return nil}
        super.init()
        setValuesForKeys(dictionary)
    }
}
