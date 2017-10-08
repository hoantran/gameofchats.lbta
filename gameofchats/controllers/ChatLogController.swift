//
//  ChatLogController.swift
//  gameofchats
//
//  Created by Hoan Tran on 9/26/17.
//  Copyright © 2017 Pego Consulting. All rights reserved.
//

import UIKit
import Firebase

class ChatLogController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var user: User? {
        didSet {
            navigationItem.title = user?.name
            observeMessages()
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
        collectionView?.alwaysBounceVertical = true 
        
        collectionView?.register(ChatMessageCell.self, forCellWithReuseIdentifier: ChatMessageCell.ID)
        
        collectionView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        
        collectionView?.keyboardDismissMode = .interactive
        setupKeyboardObserver()
    }
    
    func setupKeyboardObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidShow), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
    }
    
    @objc func handleKeyboardDidShow(){
        self.collectionView?.scrollToBottom()
    }
    
    lazy var inputContainerView: UIView = {
        let containerView = UIView()
        containerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50)
        containerView.backgroundColor = UIColor.white
        
        let uploadImageView = UIImageView()
        uploadImageView.translatesAutoresizingMaskIntoConstraints = false
        uploadImageView.image = UIImage(named: "upload_image_icon")
        uploadImageView.isUserInteractionEnabled = true
        uploadImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleUploadTap)))
        containerView.addSubview(uploadImageView)
        NSLayoutConstraint.activate([
            uploadImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor),
            uploadImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            uploadImageView.widthAnchor.constraint(equalToConstant: 44),
            uploadImageView.heightAnchor.constraint(equalToConstant: 44)
            ])
        
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send", for: UIControlState())
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        containerView.addSubview(sendButton)
        //x,y,w,h
        sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        containerView.addSubview(self.inputTextField)
        //x,y,w,h
        self.inputTextField.leftAnchor.constraint(equalTo: uploadImageView.rightAnchor , constant: 8).isActive = true
        self.inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        self.inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor).isActive = true
        self.inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        let separatorLineView = UIView()
        separatorLineView.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(separatorLineView)
        //x,y,w,h
        separatorLineView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        separatorLineView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        separatorLineView.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
        separatorLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        return containerView
    }()
    
    @objc func handleUploadTap() {
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        var imageFromPicker: UIImage?
        
//        if let url = info["UIImagePickerControllerReferenceURL"] as? URL {
//            self.profileImageURLHash = url.absoluteString.hashValue
//        }
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            imageFromPicker = editedImage
        } else if let origImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            imageFromPicker = origImage
        }
        
        if let selectedImage = imageFromPicker {
            send(selectedImage)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    private func send(_ image: UIImage) {
        upload(image, completion: {metadata in
            if let imageURL = metadata.downloadURL()?.absoluteString {
                self.post(["imageURL": imageURL, "imageWidth": image.size.width, "imageHeight": image.size.height] as [String:Any])
                
            }
        })
    }
    
    func upload(_ image: UIImage, completion: @escaping (StorageMetadata)->Void) {
        let imageName = UUID().uuidString
        let storageRef = Constants.dbMessageImage.child("\(imageName).jpg")
        if let uploadData = UIImageJPEGRepresentation(image, 0.2)  {
            storageRef.putData(uploadData, metadata: nil, completion: {(metadata, sError) in
                if sError != nil {
                    print ("Error storing message image: %@", sError ?? "")
                    return
                }
                if let metadata = metadata {
                    completion(metadata)
                }
            })
        }
    }

    private func post(_ properties: [String : Any]) {
        if  let toID = user?.id,
            let fromID = Auth.auth().currentUser?.uid
        {
            let ref = Constants.dbMessages
            let messgeRef = ref.childByAutoId()
            let timestamp:NSNumber = NSNumber(value: Int(NSDate().timeIntervalSince1970))
            var values = ["fromID": fromID, "toID": toID, "timestamp": timestamp] as [String : Any]
            properties.forEach({ values[$0] = $1 })
            messgeRef.updateChildValues(values, withCompletionBlock: {errorA, refA in
                if errorA != nil {
                    print ("Error in posting a new message : %@", errorA ?? "")
                    return
                }
                
                let userMessagesDictionary = ["/\(fromID)/\(toID)/\(messgeRef.key)": 1, "/\(toID)/\(fromID)/\(messgeRef.key)": 1]
                Constants.dbUserMessages.updateChildValues(userMessagesDictionary)
            })
            inputTextField.text = nil
        }
    }

    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    override var inputAccessoryView: UIView? {
        get {
            return inputContainerView
        }
    }
    
    override var canBecomeFirstResponder : Bool {
        return true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    var containerViewBottomAnchor: NSLayoutConstraint?

    var messages = [Message]()
    fileprivate func observeMessages() {
        if let userID = Auth.auth().currentUser?.uid, let toID = user?.id {
            Constants.dbUserMessages.child(userID).child(toID).observe(.childAdded, with: {usermessageSnap in
                Constants.dbMessages.child(usermessageSnap.key).observeSingleEvent(of: .value, with: {messageSnap in
                    if let message = Message(messageSnap) {
                        self.messages.append(message)
                        DispatchQueue.main.async {
                            self.collectionView?.reloadData()
                            self.collectionView?.scrollToBottom()
                        }
                    }
                })
            })
        }
    }
    
    @objc func handleKeyboardWillShow(notification: NSNotification) {
        let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue
        let keyboardDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue

        containerViewBottomAnchor?.constant = -keyboardFrame!.height
        UIView.animate(withDuration: keyboardDuration!, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    @objc func handleKeyboardWillHide(_ notification: Notification) {
        let keyboardDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue
        
        containerViewBottomAnchor?.constant = 0
        UIView.animate(withDuration: keyboardDuration!, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    private func estimatedSize(_ text: String) -> CGRect {
        let size = CGSize(width: 200, height: CGFloat.greatestFiniteMagnitude)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [.font: UIFont.systemFont(ofSize: CGFloat(Constants.chatTextFontSize))], context: nil)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height:CGFloat = 80
        
        let message = messages[indexPath.row]
        if let text = message.text {
            height = estimatedSize(text).height + 20
        } else if let imageWidth = message.imageWidth?.floatValue, let imageHeight = message.imageHeight?.floatValue {
            height = CGFloat(imageHeight) * CGFloat(Constants.messageImageWidth) / CGFloat(imageWidth)
        }
        return CGSize(width: view.frame.width, height: height)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChatMessageCell.ID, for: indexPath) as! ChatMessageCell
        let message = messages[indexPath.row]
        cell.textView.text = message.text
        
        setupCell(message: message, cell: cell)
        
        var width:CGFloat = CGFloat(Constants.messageImageWidth)
        if let text = message.text {
            width = estimatedSize(text).width + 20
        } else if message.imageURL != nil {
            width = CGFloat(Constants.messageImageWidth)
        }
        cell.bubbleWidthAnchor?.constant = width
        
        return cell
    }
    
    private func setupCell(message: Message, cell: ChatMessageCell) {
        if let url = user?.profileImageURL {
            cell.profileImageView.loadImage(url)
        }
        
        if message.partnerID() == message.fromID {
            cell.bubbleView.backgroundColor = Constants.chatBubbleColorForFrom
            cell.textView.textColor = UIColor.black
            cell.bubbleLeftAnchor?.isActive = true
            cell.bubbleRightAnchor?.isActive = false
            cell.profileImageView.isHidden = false
        } else {
            cell.bubbleView.backgroundColor = Constants.chatBubbleColorForTo
            cell.textView.textColor = UIColor.white
            cell.bubbleLeftAnchor?.isActive = false
            cell.bubbleRightAnchor?.isActive = true
            cell.profileImageView.isHidden = true
        }
        
        if let url = message.imageURL {
            cell.messageImageView.loadImage(url)
            cell.messageImageView.isHidden = false
            cell.bubbleView.backgroundColor = UIColor.clear
        } else {
            cell.messageImageView.isHidden = true
        }
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == inputTextField {
            handleSend()
            return true
        }
        return false
    }
    
    @objc func handleSend() {
        if let message = inputTextField.text {
            if message.count != 0 {
                self.post(["text": message] as [String:Any])
            }
        }
    }
    
}
