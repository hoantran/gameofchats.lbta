//
//  ChatMessageCell.swift
//  gameofchats
//
//  Created by Hoan Tran on 9/29/17.
//  Copyright © 2017 Pego Consulting. All rights reserved.
//

import UIKit
import AVFoundation

class ChatMessageCell: UICollectionViewCell {
    static let ID = "chatmessagecell"
    
    var message:Message?
    var chatLogController: ChatLogController?
    
    var activityIndicator:UIActivityIndicatorView = {
        let aiv = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        aiv.hidesWhenStopped = true
        aiv.translatesAutoresizingMaskIntoConstraints = false
        return aiv
    }()
    
    lazy var playButton: UIButton = {
        var b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        let image = UIImage(named: "play")
//        b.setImage(image, for: .normal)
        b.setImage(image, for: UIControlState())
        b.tintColor = UIColor.white
        b.addTarget(self, action: #selector(handlePlay), for: .touchUpInside)
        return b
    }()
    
    var bubbleView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = Constants.chatBubbleColorForTo
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
        v.isEditable = false
        return v
    }()
    
    var profileImageView: UIImageView = {
        let v = UIImageView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.image = UIImage(named: "default_user")
        v.layer.cornerRadius = 16
        v.layer.masksToBounds = true
        v.contentMode = .scaleToFill
        return v
    }()
    
    lazy var messageImageView: UIImageView = {
        let v = UIImageView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 16
        v.layer.masksToBounds = true
        v.contentMode = .scaleAspectFit
        v.backgroundColor = UIColor.black
        v.isUserInteractionEnabled = true
        v.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomTap)))
        return v
    }()
    
    var playerLayer: AVPlayerLayer?
    var player: AVPlayer?
    
    @objc func handlePlay() {
        if let videoUrlString = message?.videoURL, let url = URL(string: videoUrlString) {
            player = AVPlayer(url: url)

            player?.addObserver(self, forKeyPath: "status", options: .new, context: nil)
            
            playerLayer = AVPlayerLayer(player: player)
            playerLayer?.frame = messageImageView.bounds
            messageImageView.layer.addSublayer(playerLayer!)
            
            player?.play()
            activityIndicator.startAnimating()
            playButton.isHidden = true

            print("Attempting to play video......???")
        }
//        let videoURL = URL(string: "https://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4")
//        let player = AVPlayer(url: videoURL!)
//        let playerLayer = AVPlayerLayer(player: player)
//        playerLayer.frame = bubbleView.bounds
//        bubbleView.layer.addSublayer(playerLayer)
//        player.play()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            activityIndicator.stopAnimating()
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        playButton.isHidden = false
        willMove(toWindow: nil)
    }
    
    override func willMove(toWindow newWindow: UIWindow?) {
        activityIndicator.stopAnimating()
        playerLayer?.removeFromSuperlayer()
        player?.pause()
        bringSubview(toFront: playButton)
    }
    
    @objc func handleZoomTap(tapGesture: UITapGestureRecognizer) {
        if message?.videoURL != nil {
            return
        }
        
        if let imageView = tapGesture.view as? UIImageView {
            chatLogController?.performZoomIn(imageView: imageView)
        }
    }
    
    var bubbleWidthAnchor: NSLayoutConstraint?
    var bubbleLeftAnchor: NSLayoutConstraint?
    var bubbleRightAnchor: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(bubbleView)
        bubbleWidthAnchor = bubbleView.widthAnchor.constraint(equalToConstant: 200)
        bubbleWidthAnchor?.isActive = true
        bubbleLeftAnchor = bubbleView.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8 )
        bubbleRightAnchor = bubbleView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -8)
        bubbleRightAnchor?.isActive = true

        NSLayoutConstraint.activate([
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
        
        addSubview(profileImageView)
        NSLayoutConstraint.activate([
            profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8),
            profileImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 32),
            profileImageView.heightAnchor.constraint(equalToConstant: 32)
            ])
        
        addSubview(messageImageView)
        NSLayoutConstraint.activate([
            messageImageView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor),
            messageImageView.topAnchor.constraint(equalTo: bubbleView.topAnchor),
            messageImageView.widthAnchor.constraint(equalTo: bubbleView.widthAnchor),
            messageImageView.heightAnchor.constraint(equalTo: bubbleView.heightAnchor)
            ])
        
        addSubview(playButton)
        NSLayoutConstraint.activate([
            playButton.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 50),
            playButton.heightAnchor.constraint(equalToConstant: 50)
            ])

        addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor),
            activityIndicator.widthAnchor.constraint(equalToConstant: 50),
            activityIndicator.heightAnchor.constraint(equalToConstant: 50)
            ])

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
