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
        let ref = Firebase.Database.database().reference(fromURL: "https://gameofchats-7aae3.firebaseio.com/")
        let userRef = ref.child("users").child(uid)
        userRef.updateChildValues(values, withCompletionBlock: {(uError, uRef) in
            if uError != nil {
                print(uError ?? "")
                return
            }
            self.dismiss(animated: true, completion: nil)
        })
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
            
            let imageName = UUID().uuidString
            let storageRef = Storage.storage().reference().child("profile_images").child("\(imageName).png")
            if let uploadData = UIImagePNGRepresentation(self.profileImageView.image!) {
                storageRef.putData(uploadData, metadata: nil, completion: {(metadata, sError) in
                    if sError != nil {
                        print ("Error storing profile image: %@", sError ?? "")
                        return
                    }
                    
                    if let profileImageURL = metadata?.downloadURL()?.absoluteString {
                        let values = ["name": name, "email": email, "profileImageURL": profileImageURL]
                        self.registerUserIntoDatabase(uid, values: values)
                    }
                })
            }
        })
    }
}

















