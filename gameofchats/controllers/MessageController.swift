//
//  MessageController.swift
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

class MessageController: UITableViewController {

    var messages = [Message]()
    var messageDictionary = [String:Message]()
    
    fileprivate func checkIfUserIsLoggedIn() {
        if Auth.auth().currentUser?.uid == nil {
            perform(#selector(handleLogout))
        } else {
           showUserName()
        }
    }
    
    fileprivate func showUserName() {
        if let uid = Auth.auth().currentUser?.uid {
            Database.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: {(snapshot) in
                if let user = User(snapshot) {
                    self.setupNavBar(user)
                }
            })
        }
    }
    
    var profileImageView: UIImageView?
    
    func setupNavBar(_ user: User) {
        let titleView = UIView()
        titleView.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
        titleView.backgroundColor = UIColor.red
        
//        // HACK
//        self.profileImageView = UIImageView()
//        if let profileImageView = profileImageView {
//            profileImageView.translatesAutoresizingMaskIntoConstraints = false
//            profileImageView.contentMode = .scaleAspectFill
//            profileImageView.layer.cornerRadius = 20
//            profileImageView.clipsToBounds = true
//            profileImageView.loadImage(user.profileImageURL)
//
//            titleView.addSubview(profileImageView)
//
//            //ios 9 constraint anchors
//            //need x,y,width,height anchors
//            profileImageView.leftAnchor.constraint(equalTo: titleView.leftAnchor).isActive = true
//            profileImageView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
//            profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
//            profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
//
//            let nameLabel = UILabel()
//
//            titleView.addSubview(nameLabel)
//            nameLabel.text = user.name
//            nameLabel.translatesAutoresizingMaskIntoConstraints = false
//            //need x,y,width,height anchors
//            nameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8).isActive = true
//            nameLabel.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
//            nameLabel.widthAnchor.constraint(equalTo: titleView.widthAnchor).isActive = true
//            nameLabel.heightAnchor.constraint(equalTo: titleView.heightAnchor).isActive = true
//        }

// PER VIDEO'S INSTRUCTION
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        titleView.addSubview(containerView)

        self.profileImageView = UIImageView()
        if let profileImageView = profileImageView {
            profileImageView.translatesAutoresizingMaskIntoConstraints = false
            profileImageView.contentMode = .scaleAspectFill
            profileImageView.layer.cornerRadius = 20
            profileImageView.clipsToBounds = true
            profileImageView.loadImage(user.profileImageURL)

            containerView.addSubview(profileImageView)

            //ios 9 constraint anchors
            //need x,y,width,height anchors
            profileImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
            profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
            profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
            profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true

            let nameLabel = UILabel()

            containerView.addSubview(nameLabel)
            nameLabel.text = user.name
            nameLabel.translatesAutoresizingMaskIntoConstraints = false
            //need x,y,width,height anchors
            nameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8).isActive = true
            nameLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
            nameLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
            nameLabel.heightAnchor.constraint(equalTo: profileImageView.heightAnchor).isActive = true
        }
        containerView.centerXAnchor.constraint(equalTo: titleView.centerXAnchor).isActive = true
        containerView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        
        self.navigationItem.titleView = titleView
    }
    
    @objc func showChatController(user: User) {
        let chatLogController = ChatLogController(collectionViewLayout: UICollectionViewFlowLayout())
        chatLogController.user = user
        navigationController?.pushViewController(chatLogController, animated: true)
    }
        
//        titleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showChatController)))
//    }
//
//    @objc func showChatController() {
//        print("hey")
//        let controller = ChatLogController()
//        navigationController?.pushViewController(controller, animated: true)
//    }
    
    @objc func handleNewMessage() {
        let controller = NewMessageController()
        controller.messageController = self
        let navController = UINavigationController(rootViewController: controller)
        present(navController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        
        let image = UIImage(named: "new_message_icon")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: image , style: .plain, target: self, action: #selector(handleNewMessage))
        
        tableView.register(UserCell.self, forCellReuseIdentifier: UserCell.cellID)
        
        checkIfUserIsLoggedIn()
        observeMessages()
    }
    
    func reloadMessages() {
        filterMessages()
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func filterMessages() {
        self.messages = getMessagesForCurrentUser(Array(self.messageDictionary.values))
        self.messages.sort(by: {m1, m2 in
            if let m1Time = m1.timestamp?.intValue, let m2Time = m2.timestamp?.intValue {
                return m1Time > m2Time
            } else {
                return false
            }
        })
    }
    
    func getMessagesForCurrentUser(_ messages: [Message]) -> [Message] {
        if let currentID = Auth.auth().currentUser?.uid {
            return messages.filter({m in
                return m.toID == currentID || m.fromID == currentID
            })
        } else {
            return [Message]()
        }
    }
    
    func observeMessages() {
        let ref = Database.database().reference().child("messages")
        ref.removeAllObservers()
        ref.observe(.childAdded, with: {snapshot in
            if let message = Message(snapshot) {
                if let toID = message.toID {
                    if let existing = self.messageDictionary[toID] {
                        if let questionedTime = message.timestamp?.intValue, let existedTime = existing.timestamp?.intValue {
                            if questionedTime <= existedTime {
                                return
                            }
                        }
                    }
                    
                    self.messageDictionary[toID] = message
                    self.filterMessages()
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        })
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UserCell.cellID, for: indexPath) as! UserCell
        cell.message = self.messages[indexPath.row]
        return cell
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showUserName()
    }
    
    @objc func handleLogout() {
        if Auth.auth().currentUser?.uid != nil {
            do {
                try Auth.auth().signOut()
            } catch let signOutError as NSError {
                print ("Error signing out: %@", signOutError)
            }
        }
        
        let loginController = LoginViewController()
        loginController.messageController = self
        present(loginController, animated: true, completion: nil)
    }
}

