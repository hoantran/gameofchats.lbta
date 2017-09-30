//
//  ChatMessageCell.swift
//  gameofchats
//
//  Created by Hoan Tran on 9/29/17.
//  Copyright © 2017 Pego Consulting. All rights reserved.
//

import UIKit

class ChatMessageCell: UICollectionViewCell {
    static let ID = "chatmessagecell"
    
    var bubbleView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor(r: 0, g: 137, b: 249)
        v.layer.cornerRadius = 16
        v.layer.masksToBounds = true
        return v
    }()
    
    var textView: UITextView = {
        let v = UITextView()
        v.font = UIFont.systemFont(ofSize: CGFloat(Constants.chatTextFontSize))
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.clear
        v.textColor = UIColor.white
        return v
    }()
    
    var bubbleWidthAnchor: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(bubbleView)
        bubbleWidthAnchor = bubbleView.widthAnchor.constraint(equalToConstant: 300)
        bubbleWidthAnchor?.isActive = true
        NSLayoutConstraint.activate([
            bubbleView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -8),
            bubbleView.topAnchor.constraint(equalTo: self.topAnchor),
            bubbleView.heightAnchor.constraint(equalTo: self.heightAnchor)
            ])
        
        addSubview(textView)
        NSLayoutConstraint.activate([
            textView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 8),
            textView.topAnchor.constraint(equalTo: self.topAnchor),
            textView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor),
            textView.heightAnchor.constraint(equalTo: self.heightAnchor)
            ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
