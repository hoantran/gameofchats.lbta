//
//  Extensions.swift
//  gameofchats
//
//  Created by Hoan Tran on 9/21/17.
//  Copyright © 2017 Pego Consulting. All rights reserved.
//

import UIKit
import Firebase

struct Constants {
    static let dbRoot = Database.database().reference()
    static let dbMessages = Constants.dbRoot.child("messages")
    static let dbUsers = Constants.dbRoot.child("users")
    static let dbUserMessages = Constants.dbRoot.child("user-messages")
}


let imageCache = NSCache<NSString,UIImage>()

extension UIImageView {
    
    func loadImage(_ urlStr: String?) {
        if let profileURL = urlStr, let urlComponents = URLComponents(string: profileURL) {
            if let cachedImage = imageCache.object(forKey: profileURL as NSString) {
                DispatchQueue.main.async {
                    self.image = cachedImage
                }
                return
            }
            
            let session = URLSession(configuration: .default)
            guard let url = urlComponents.url else { return }
            
            let datatask = session.dataTask(with: url) { (data, response, error) in
                if error == nil {
                    if let downloadedImage = UIImage(data: data!) {
                        imageCache.setObject(downloadedImage, forKey: profileURL as NSString)
                        DispatchQueue.main.async {
                            self.image = downloadedImage
                        }
                    }
                } else {
                    print(error!.localizedDescription)
                }
            }
            datatask.resume()
        }
    }
}
