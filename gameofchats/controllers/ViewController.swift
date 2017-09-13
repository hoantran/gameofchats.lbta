//
//  ViewController.swift
//  gameofchats
//
//  Created by Hoan Tran on 9/6/17.
//  Copyright © 2017 Pego Consulting. All rights reserved.
//

import UIKit
import Firebase

extension UIColor {
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat) {
        self.init(red: r/255, green: g/255, blue: b/255, alpha: 1)
    }
}

class ViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.cyan
        
//        let ref = Firebase.Database().reference("https://gameofchats-7aae3.firebaseio.com/")
//        let ref = Firebase.Database.database().reference(fromURL: "https://gameofchats-7aae3.firebaseio.com/")
//        ref.updateChildValues(["someValue":123432])
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        
//        handleLogout()
    }
    
    @objc func handleLogout() {
        let loginController = LoginViewController()
        present(loginController, animated: true, completion: nil)
    }
}

