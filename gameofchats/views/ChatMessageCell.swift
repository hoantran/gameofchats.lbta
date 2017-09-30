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
    
    var textView: UITextView = {
        let v = UITextView()
        v.font = UIFont.systemFont(ofSize: 16)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.cyan
        return v
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(textView)
        NSLayoutConstraint.activate([
            textView.rightAnchor.constraint(equalTo: self.rightAnchor),
            textView.topAnchor.constraint(equalTo: self.topAnchor),
            textView.widthAnchor.constraint(equalToConstant: 300),
            textView.heightAnchor.constraint(equalTo: self.heightAnchor)
            ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
