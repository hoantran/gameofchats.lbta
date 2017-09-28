//
//  Message.swift
//  gameofchats
//
//  Created by Hoan Tran on 9/28/17.
//  Copyright © 2017 Pego Consulting. All rights reserved.
//

import UIKit
import Firebase

class Message: NSObject {
    @objc var text: String?
    @objc var fromID: String?
    @objc var toID: String?
    @objc var timestamp: NSNumber?
    
    init?(_ snapshot: DataSnapshot) {
        guard let dictionary = snapshot.value as? [String: Any] else { return nil}
        super.init()
        setValuesForKeys(dictionary)
    }
    
    init(dictionary: [AnyHashable: Any]) {
        self.text = dictionary["text"] as? String
        self.fromID = dictionary["fromID"] as? String
        self.toID = dictionary["toID"] as? String
        self.timestamp = dictionary["timestamp"] as? NSNumber
    }
}
