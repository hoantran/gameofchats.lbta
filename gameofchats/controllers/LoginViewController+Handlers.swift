//
//  LoginViewController+Handlers.swift
//  gameofchats
//
//  Created by Hoan Tran on 9/21/17.
//  Copyright © 2017 Pego Consulting. All rights reserved.
//

import UIKit
import Firebase


extension LoginViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @objc func handleSelectProfileImageView() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        var imageFromPicker: UIImage?
        
        if let url = info["UIImagePickerControllerReferenceURL"] as? URL {
            self.profileImageURLHash = url.absoluteString.hashValue
        }
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            imageFromPicker = editedImage
        } else if let origImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            imageFromPicker = origImage
        }
        
        if let selectedImage = imageFromPicker {
            profileImageView.image = selectedImage
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    fileprivate func registerUserIntoDatabase(_ uid: String, values: [String: Any]) {
        let ref = Firebase.Database.database().reference()
        let userRef = ref.child("users").child(uid)
        userRef.updateChildValues(values, withCompletionBlock: {(uError, uRef) in
            if uError != nil {
                print(uError ?? "")
                return
            }
            
            let user = User(dictionary: values)
            self.messageController?.setupNavBar(user)
            self.dismiss(animated: true, completion: nil)
        })
    }
    fileprivate func updateProfileImageURL(_ uid: String, user: User) {
        uploadProfileImage(completion: {metadata in
            let ref = Firebase.Database.database().reference(fromURL: LoginViewController.MAIN_REF)
            let userRef = ref.child("users").child(uid)
            if let profileImageURL = metadata.downloadURL()?.absoluteString {
                let values = ["profileImageURL": profileImageURL, "profileImageURLHash": String(describing: self.profileImageURLHash)]
                userRef.updateChildValues(values, withCompletionBlock: {(uError, uRef) in
                    if uError != nil {
                        print("Can not update profile image URL hash: ", uError ?? "")
                    }
                    self.messageController?.profileImageView?.loadImage(profileImageURL)
                })
                
            }
        })
    }
    
    
    @objc func handleLoginRegister() {
        if loginRegisterSegmentedControl.selectedSegmentIndex == Segment.login.rawValue {
            handleLogin()
        } else {
            handleRegister()
        }
    }
    func handleLogin() {
        guard
            let email = self.textFields[TextField.email.rawValue].text,
            let password = self.textFields[TextField.password.rawValue].text else {
                print("invalid form")
                return
        }
        Auth.auth().signIn(withEmail: email, password: password, completion: { (user, error) in
            if error == nil {
                print(user?.displayName ?? "User logged in")
                self.dismiss(animated: true, completion: nil)
                if let uid = user?.uid {
                    self.updateProfileImageToServer(uid)
                }
            } else {
                print ("Error signing in: %@", error ?? "")
            }
        })
    }
    
    fileprivate func updateProfileImageToServer(_ uid: String) {
        Database.database().reference().child("users").child(uid).observe(.value, with: {(snapshot) in
            if let user = User(snapshot), let serverHash = user.profileImageURLHash {
                if self.profileImageURLHash != -1 && Int(serverHash) != self.profileImageURLHash{
                    self.updateProfileImageURL(uid, user: user)
                }
            }
        })
    }
    
    func uploadProfileImage(completion: @escaping (StorageMetadata)->Void) {
        let imageName = UUID().uuidString
        let storageRef = Storage.storage().reference().child("profile_images").child("\(imageName).jpg")
        //            if let uploadData = UIImagePNGRepresentation(self.profileImageView.image!) {
        if let uploadData = UIImageJPEGRepresentation(self.profileImageView.image!, 0.1)  {
            storageRef.putData(uploadData, metadata: nil, completion: {(metadata, sError) in
                if sError != nil {
                    print ("Error storing profile image: %@", sError ?? "")
                    return
                }
                if let metadata = metadata {
                    completion(metadata)
                }
            })
        }
    }
    
    func handleRegister() {
        guard
            let name = self.textFields[TextField.name.rawValue].text,
            let email = self.textFields[TextField.email.rawValue].text,
            let password = self.textFields[TextField.password.rawValue].text else {
                print("invalid form")
                return
        }
        
        Firebase.Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
            if error != nil {
                print(error ?? "")
                return
            }
            
            guard let uid = user?.uid else { return }
            
            self.uploadProfileImage(completion: {metadata in
                if let profileImageURL = metadata.downloadURL()?.absoluteString {
                    let values = ["name": name, "email": email, "profileImageURL": profileImageURL, "profileImageURLHash": String (describing: self.profileImageURLHash)]
                    self.registerUserIntoDatabase(uid, values: values)
                }
            })
        })
    }
}

















