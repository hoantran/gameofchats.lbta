//
//  NewMessageController.swift
//  gameofchats
//
//  Created by Hoan Tran on 9/20/17.
//  Copyright © 2017 Pego Consulting. All rights reserved.
//

import UIKit
import Firebase

class NewMessageController: UITableViewController {
    let cellID = "cellID"
    var users = [User]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UserCell.self, forCellReuseIdentifier: UserCell.cellID)
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
        
        fetchUsers()
    }
    
    fileprivate func fetchUsers() {
        Database.database().reference().child("users").observe(.childAdded, with: {(snapshot) in
            if let user = User(snapshot) {
                self.users.append(user)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        })
    }
    
    @objc func handleCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UserCell.cellID, for: indexPath) as! UserCell
        let user = users[indexPath.row]
        cell.textLabel?.text = user.name
        cell.detailTextLabel?.text = user.email

        cell.profileImageView.loadImage(user.profileImageURL)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
    
    var messageController: MessageController?
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: true, completion: {
            self.messageController?.showChatController(user: self.users[indexPath.row])
        })
    }
    
}

