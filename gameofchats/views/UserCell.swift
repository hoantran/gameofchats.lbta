//
//  UserCell.swift
//  gameofchats
//
//  Created by Hoan Tran on 9/28/17.
//  Copyright © 2017 Pego Consulting. All rights reserved.
//

import UIKit
import Firebase

class UserCell:UITableViewCell {
    static let cellID = "cellID"
    
    var message: Message? {
        didSet {
            if let toID = message?.toID {
                let ref = Database.database().reference().child("users").child(toID)
                ref.observeSingleEvent(of: .value, with: { snapshot in
                    if let user = User(snapshot) {
                        self.textLabel?.text = user.name
                        self.profileImageView.loadImage(user.profileImageURL)
                    }
                })
            }
            
            self.detailTextLabel?.text = message?.text
            if let seconds = message?.timestamp?.doubleValue {
                let date = Date(timeIntervalSince1970: seconds)
                let formater = DateFormatter()
                formater.dateFormat = "MM/dd/yy hh:mm:ss a"
                self.timeLabel.text = formater.string(from: date)
            }
        }
    }
    
    let timeLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00:00"
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = UIColor.lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let profileImageView : UIImageView = {
        let v = UIImageView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.contentMode = .scaleAspectFill
        v.image = UIImage(named: "default_user")
        v.layer.cornerRadius = 20
        v.layer.masksToBounds = true
        
        return v
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        textLabel?.frame = CGRect(x: 56, y: textLabel!.frame.origin.y, width: textLabel!.frame.width, height: textLabel!.frame.height)
        detailTextLabel?.frame = CGRect(x: 56, y: detailTextLabel!.frame.origin.y, width: detailTextLabel!.frame.width, height: detailTextLabel!.frame.height)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        addSubview(profileImageView)
        profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        addSubview(timeLabel)
        
        NSLayoutConstraint.activate([
            timeLabel.rightAnchor.constraint(equalTo: self.rightAnchor),
            timeLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 15),
            timeLabel.widthAnchor.constraint(equalToConstant: 150),
            ])
        if let heightAnchor = textLabel?.heightAnchor {
            NSLayoutConstraint.activate([
                timeLabel.heightAnchor.constraint(equalTo: heightAnchor)
                ])
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
