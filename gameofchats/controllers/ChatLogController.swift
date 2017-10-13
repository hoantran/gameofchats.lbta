//
//  ChatLogController.swift
//  gameofchats
//
//  Created by Hoan Tran on 9/26/17.
//  Copyright © 2017 Pego Consulting. All rights reserved.
//

import UIKit
import Firebase
import MobileCoreServices
import AVFoundation

class ChatLogController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var user: User? {
        didSet {
            navigationItem.title = user?.name
            observeMessages()
        }
    }
    
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
    
    lazy var inputContainerView: ChatInputContainerView = {
        let frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50)
        let chatContainerView = ChatInputContainerView(frame: frame)
        chatContainerView.chatLogController = self
        return chatContainerView
    }()
    
    @objc func handleUploadTap() {
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        imagePicker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let videoURL = info[UIImagePickerControllerMediaURL] as? URL {
            handleVideoSelected(videoURL)
        } else {
            handleImageSelected(info)
        }
        dismiss(animated: true, completion: nil)
    }
    
    fileprivate func upload(videoFileURL: URL, completion: @escaping (String?)->Void) {
        let fileName =  UUID().uuidString + ".mov"
        
        let uploadTask = Constants.dbMessageMovies.child(fileName).putFile(from: videoFileURL, metadata: nil, completion: {metadata, error in
            if error != nil {
                print ("Error storing video: %@", error ?? "")
                return
            }
            
            completion(metadata?.downloadURL()?.absoluteString)
        })
        
        uploadTask.observe(.progress, handler: {snapshot in
            if let completedUnitCount = snapshot.progress?.completedUnitCount, let totalUnitCount = snapshot.progress?.totalUnitCount {
                let uploadPercentage : Float64 = Float64(completedUnitCount) * 100 / Float64(totalUnitCount)
                self.navigationItem.title = String(format: "%.0f", uploadPercentage) + " %"
            }
        })
        
        uploadTask.observe(.success, handler: {snapshot in
            self.navigationItem.title = self.user?.name
        })
    }
    
    private func handleVideoSelected(_ fileURL: URL) {
        upload(videoFileURL: fileURL, completion: {storageURL in
            if  let videoStorageURL = storageURL,
                let thumnailImage = self.getVideoThumbnail(fileURL)  {
                    self.upload(thumnailImage, completion: {imageStorageURL in
                        self.post(["videoURL":videoStorageURL, "imageURL": imageStorageURL, "imageWidth": thumnailImage.size.width, "imageHeight": thumnailImage.size.height] as [String:Any])
                })
            }
        })
    }
    
    private func getVideoThumbnail(_ fileURL: URL)->UIImage? {
        let asset = AVAsset(url: fileURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        do {
            let thumbnailCGImage = try imageGenerator.copyCGImage(at: CMTimeMake(1, 60), actualTime: nil)
            return UIImage(cgImage: thumbnailCGImage)
        } catch let err {
            print ("Error getting thumbnail image for video: %@", err)
        }
        
        return nil
    }
    
    private func handleImageSelected(_ info: [String: Any]) {
        var imageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            imageFromPicker = editedImage
        } else if let origImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            imageFromPicker = origImage
        }
        
        if let selectedImage = imageFromPicker {
            send(selectedImage)
        }
    }
    
    private func send(_ image: UIImage) {
        upload(image, completion: {storageImageURL in
            self.post(["imageURL": storageImageURL, "imageWidth": image.size.width, "imageHeight": image.size.height] as [String:Any])
        })
    }
    
    func upload(_ image: UIImage, completion: @escaping (String)->Void) {
        let imageName = UUID().uuidString
        let storageRef = Constants.dbMessageImage.child("\(imageName).jpg")
        if let uploadData = UIImageJPEGRepresentation(image, 0.2)  {
            storageRef.putData(uploadData, metadata: nil, completion: {(metadata, sError) in
                if sError != nil {
                    print ("Error storing message image: %@", sError ?? "")
                    return
                }
                if let storageImageURL = metadata?.downloadURL()?.absoluteString {
                    completion(storageImageURL)
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
            inputContainerView.inputTextField.text = nil
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
        
        cell.message = message
        
        var width:CGFloat = CGFloat(Constants.messageImageWidth)
        if let text = message.text {
            width = estimatedSize(text).width + 20
            cell.textView.isHidden = false
        } else if message.imageURL != nil {
            width = CGFloat(Constants.messageImageWidth)
            cell.textView.isHidden = true
            cell.chatLogController = self
        }
        cell.bubbleWidthAnchor?.constant = width
        
        cell.playButton.isHidden = message.videoURL == nil
        
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
    
    @objc func handleSend() {
        if let message = inputContainerView.inputTextField.text {
            if message.count != 0 {
                self.post(["text": message] as [String:Any])
            }
        }
    }
    
    var startingFrame: CGRect?
    var blackBkgView: UIView?
    var startingImageView: UIImageView?
    
    func performZoomIn(imageView: UIImageView) {
        startingImageView = imageView
        startingFrame = imageView.superview?.convert(imageView.frame, to: nil)
        if let startFrame = startingFrame {
            let zoomView = UIImageView(frame: startFrame)
            zoomView.backgroundColor = UIColor.red
            zoomView.image = imageView.image
            zoomView.layer.cornerRadius = 16
            zoomView.layer.masksToBounds = true
            zoomView.isUserInteractionEnabled = true
            zoomView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomOut)))
            if let keyWindow = UIApplication.shared.keyWindow {
                startingImageView?.isHidden = true
                blackBkgView = UIView(frame: keyWindow.frame)
                blackBkgView?.backgroundColor = UIColor.black
                blackBkgView?.alpha = 0
                keyWindow.addSubview(blackBkgView!)
                
                keyWindow.addSubview(zoomView)
                
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
                    zoomView.layer.cornerRadius = 0
                    self.blackBkgView?.alpha = 1
                    self.inputContainerView.alpha = 0
                    let height = startFrame.height * keyWindow.frame.width / startFrame.width
                    
                    zoomView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
                    zoomView.center = keyWindow.center
                }, completion: nil)
            }
        }
    }
    
    @objc func handleZoomOut(gesture: UITapGestureRecognizer) {
        if let zoomOutView = gesture.view {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.inputContainerView.alpha = 1
                zoomOutView.layer.cornerRadius = 16
                if let startFrame = self.startingFrame {
                    zoomOutView.frame = startFrame
                }
                self.blackBkgView?.alpha = 0
            }, completion: { isFinished in
                gesture.view?.removeFromSuperview()
                self.startingImageView?.isHidden = false
            })
        }
    }
    
}
