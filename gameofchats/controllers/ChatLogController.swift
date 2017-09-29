//
//  ChatLogController.swift
//  gameofchats
//
//  Created by Hoan Tran on 9/26/17.
//  Copyright © 2017 Pego Consulting. All rights reserved.
//

import UIKit
import Firebase

class ChatLogController: UICollectionViewController, UITextFieldDelegate {
    var user: User? {
        didSet {
            navigationItem.title = user?.name
        }
    }
    
    lazy var inputTextField:UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.placeholder = "Enter message ..."
        tf.autocorrectionType = .no
        tf.delegate = self
        return tf
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.backgroundColor = UIColor.white
        setupInputParts()
    }

    fileprivate func setupInputParts() {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
//        if #available(iOS 11, *) {
            let guide = view.safeAreaLayoutGuide
            NSLayoutConstraint.activate([
                containerView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
                containerView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
                containerView.heightAnchor.constraint(equalToConstant: 50),
                containerView.bottomAnchor.constraint(equalTo: guide.bottomAnchor)
                ])
//        } else {
//            let standardSpacing: CGFloat = 8.0
//            NSLayoutConstraint.activate([
//                containerView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: standardSpacing),
//                containerView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor, constant: standardSpacing),
//                containerView.widthAnchor.constraint(equalTo: view.widthAnchor),
//                containerView.heightAnchor.constraint(equalToConstant: 50)
//                ])
//        }
        
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        containerView.addSubview(sendButton)
        NSLayoutConstraint.activate([
            sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor),
            sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 80),
            sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor)
            ])
        
        containerView.addSubview(inputTextField)
        NSLayoutConstraint.activate([
            inputTextField.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 8),
            inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor),
            inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor)
            ])
        
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        containerView.addSubview(separator)
        NSLayoutConstraint.activate([
            separator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            separator.topAnchor.constraint(equalTo: containerView.topAnchor),
            separator.widthAnchor.constraint(equalTo: containerView.widthAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1)
            ])
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == inputTextField {
            handleSend()
            return true
        }
        return false
    }
    
    @objc func handleSend() {
        if  let message = inputTextField.text,
            let toID = user?.id,
            let fromID = Auth.auth().currentUser?.uid {
            let ref = Constants.dbMessages
            let messgeRef = ref.childByAutoId()
            let timestamp:NSNumber = NSNumber(value: Int(NSDate().timeIntervalSince1970))
            let values = ["text": message, "fromID": fromID, "toID": toID, "timestamp": timestamp] as [String : Any]
            messgeRef.updateChildValues(values, withCompletionBlock: {errorA, refA in
                if errorA != nil {
                    print ("Error in saving a new message : %@", errorA ?? "")
                    return
                }
                let userMessagesRef = Constants.dbUserMessages.child(fromID)
                let set = [messgeRef.key:1]
                userMessagesRef.updateChildValues(set, withCompletionBlock: {errorB, refB in
                    if errorB != nil {
                        print ("Error in saving a user message : %@", errorB ?? "")
                        return
                    }
                })
                
                Constants.dbUserMessages.child(toID).updateChildValues([messgeRef.key:1])
                
            })
            inputTextField.text = ""
        }
    }
    
}
