//
//  LoginViewController.swift
//  gameofchats
//
//  Created by Hoan Tran on 9/6/17.
//  Copyright © 2017 Pego Consulting. All rights reserved.
//

import UIKit
import Firebase

// https://quinesoft.de/2016/05/23/swift-enumerate-iterate-enum/
protocol EnumerableEnum: RawRepresentable {
    static func allValues() -> [Self]
}
extension EnumerableEnum where RawValue == Int {
    static func allValues() -> [Self] {
        var index = -1
        return Array(AnyIterator {
            index += 1
            return Self(rawValue: Int(index))
            }
        )
    }
}

class TextFieldSeparator: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(r: 220, g: 220, b: 220)
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class LoginViewController: UIViewController, UIGestureRecognizerDelegate {
    enum TextField: Int, EnumerableEnum {
        case name = 0
        case email
        case password
        case count
        
        var string: String {
            return String(describing: self)
        }
    }
    
    enum Segment: Int {
        case login = 0
        case register
    }
    
    var messageController: MessageController?
    
    static let MAIN_REF = "https://gameofchats-7aae3.firebaseio.com/"
    
    var profileImageURLHash = -1
    
    let inputsContainerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.white
        v.layer.cornerRadius = 5
        v.layer.masksToBounds = true
        return v
    }()
    
    let loginRegisterButton: UIButton = {
        let b = UIButton(type: .system)
        b.backgroundColor = UIColor(r: 80, g: 101, b: 161)
        b.setTitle("Register", for: .normal)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setTitleColor(UIColor.white, for: .normal)
        b.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        b.addTarget(self, action: #selector(handleLoginRegister), for: .touchUpInside)
        return b
    }()
    
    let textFields: [UITextField] = {
        let fs:[UITextField] = [Int](0...(TextField.count.rawValue-1)).map({ index in
            let tf = UITextField()
            tf.placeholder = TextField.allValues()[index].string.capitalized
            tf.translatesAutoresizingMaskIntoConstraints = false
            return tf
        })
        return fs
    }()
    
    var textFieldConstraints = [NSLayoutConstraint]()
    
    lazy var profileImageView: UIImageView = {
        let v = UIImageView()
        v.image = UIImage(named: "gameofthrones_splash")
        v.translatesAutoresizingMaskIntoConstraints = false
        v.contentMode = .scaleAspectFill
        v.isUserInteractionEnabled = true
        v.addGestureRecognizer( UITapGestureRecognizer(target: self, action: #selector(handleSelectProfileImageView)) )
        return v
    }()
    
    var loginRegisterSegmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Login", "Register"])
        sc.tintColor = UIColor.white
        sc.translatesAutoresizingMaskIntoConstraints = false
        sc.selectedSegmentIndex = 1;
        sc.addTarget(self, action: #selector(handleLoginRegisterChange), for: .valueChanged)
        return sc
    }()
    
    @objc func handleLoginRegisterChange(){
        let title = loginRegisterSegmentedControl.titleForSegment(at: loginRegisterSegmentedControl.selectedSegmentIndex)
        loginRegisterButton.setTitle(title, for: .normal)
        
        inputsContainerViewHeightAnchor?.constant = loginRegisterSegmentedControl.selectedSegmentIndex == Segment.login.rawValue ? 100 : 150
        
        let length = loginRegisterSegmentedControl.selectedSegmentIndex == Segment.login.rawValue ? self.textFields.count - 1 : self.textFields.count
        for(i, tf) in (self.textFieldConstraints.enumerated()) {
            tf.isActive = false
            let multiplier:CGFloat = i == 0 && loginRegisterSegmentedControl.selectedSegmentIndex == Segment.login.rawValue ? 0 : 1/CGFloat(length)
            self.textFieldConstraints[i] = textFields[i].heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: multiplier)
            self.textFieldConstraints[i].isActive = true
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    fileprivate func setupTextFields(_ container: UIView) {
        let length = self.textFields.count
        var lastElement:UIView = container
        for( i, tf) in self.textFields.enumerated() {
            container.addSubview(tf)
            tf.topAnchor.constraint(equalTo: lastElement.topAnchor).isActive = true
            tf.leftAnchor.constraint(equalTo: container.leftAnchor, constant: 12).isActive = true
            tf.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
            textFieldConstraints.append(tf.heightAnchor.constraint(equalTo: container.heightAnchor, multiplier: 1/CGFloat(length)))
            textFieldConstraints[i].isActive = true
            lastElement = tf
            tf.delegate = self
            
            if length != 1 && i < (length-1) {
                let s1 = TextFieldSeparator()
                container.addSubview(s1)
                s1.leftAnchor.constraint(equalTo: container.leftAnchor).isActive = true
                s1.topAnchor.constraint(equalTo: lastElement.bottomAnchor).isActive = true
                s1.widthAnchor.constraint(equalTo: container.widthAnchor).isActive = true
                s1.heightAnchor.constraint(equalToConstant: 1).isActive = true
                lastElement = s1
            }
        }
    }
    
    var inputsContainerViewHeightAnchor: NSLayoutConstraint?
    
    fileprivate func setupInputsContainerView() {
        inputsContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        inputsContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        inputsContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -24).isActive = true
        inputsContainerViewHeightAnchor = inputsContainerView.heightAnchor.constraint(equalToConstant: 150)
        inputsContainerViewHeightAnchor?.isActive = true
        
        setupTextFields(inputsContainerView)
        
        textFields[TextField.password.rawValue].isSecureTextEntry = true
    }
    
    fileprivate func setupLoginRegisterButton() {
        loginRegisterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loginRegisterButton.topAnchor.constraint(equalTo: inputsContainerView.bottomAnchor, constant: 12).isActive = true
        loginRegisterButton.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        loginRegisterButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    fileprivate func setupProfileImage() {
        profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        profileImageView.bottomAnchor.constraint(equalTo: loginRegisterSegmentedControl.topAnchor, constant: -12).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 150).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 150).isActive = true
    }
    
    fileprivate func setupLoginRegisterSegmentedControl() {
        loginRegisterSegmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loginRegisterSegmentedControl.bottomAnchor.constraint(equalTo: inputsContainerView.topAnchor, constant: -12).isActive = true
        loginRegisterSegmentedControl.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor, multiplier: 1).isActive = true
        loginRegisterSegmentedControl.heightAnchor.constraint(equalToConstant: 36)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(r: 61, g: 91, b: 151)
        
        view.addSubview(inputsContainerView)
        view.addSubview(loginRegisterButton)
        view.addSubview(profileImageView)
        view.addSubview(loginRegisterSegmentedControl)
        view.bringSubview(toFront: profileImageView)
        
        setupInputsContainerView()
        setupLoginRegisterButton()
        setupProfileImage()
        setupLoginRegisterSegmentedControl()
    }
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleLoginRegister()
        return true
    }
}






