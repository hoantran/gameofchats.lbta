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
        messages.removeAll()
        messageDictionary.removeAll()
        tableView.reloadData()
        observeUserMessages()
        
        let titleView = UIView()
        titleView.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
        titleView.backgroundColor = UIColor.red

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
    }
    
    fileprivate func fetchMessage(_ messageID: String) {
        let messageRef = Constants.dbMessages.child(messageID)
        messageRef.observeSingleEvent(of: .value, with: {messageSnap in
            if  let message = Message(messageSnap),
                let key = message.partnerID() {
                self.messageDictionary[key] = message
                self.attemptReloadOfTable()
            }
        })
    }
    
    func observeUserMessages(){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let ref = Constants.dbUserMessages.child(uid)
        ref.observe(.childAdded, with: {snapshot in
            let userId = snapshot.key
            Constants.dbUserMessages.child(uid).child(userId).observe(.childAdded, with: {snapA in
                let messageID = snapA.key
                self.fetchMessage(messageID)
            })
        })
    }

    private func attemptReloadOfTable() {
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.handleReloadTable), userInfo: nil, repeats: false)
    }
    
    var timer: Timer?
    
    @objc func handleReloadTable() {
        filterMessages()
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func filterMessages() {
        self.messages = Array(self.messageDictionary.values)
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(messages[indexPath.row])
        if let partnerID = messages[indexPath.row].partnerID() {
            let ref = Constants.dbUsers.child(partnerID)
            ref.observeSingleEvent(of: .value, with: {snapshot in
                if let user = User(snapshot) {
                    self.showChatController(user: user)
                }
            })
        }
        
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

