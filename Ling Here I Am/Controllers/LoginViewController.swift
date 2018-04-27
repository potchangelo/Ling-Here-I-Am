//
//  LoginViewController.swift
//  Ling Here I Am
//
//  Created by Potchara Puttawanchai on 26/4/2561 BE.
//  Copyright © 2561 Potchara Puttawanchai. All rights reserved.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {
    
    // MARK: Variables : Storyboard UI
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    
    // MARK: - Functions : Lifecycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Functions : Storyboard UI actions

    @IBAction func loginClicked(_ sender: UIButton) {
        let email = self.emailTextField.text!
        let password = self.passwordTextField.text!
        self.errorLabel.isHidden = true
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            if let error = error {
                print("Firebase : login error = \(error.localizedDescription)")
                self.errorLabel.text = error.localizedDescription
                self.errorLabel.isHidden = false
                return
            }
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func backClicked(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
}

// MARK: - Extension : UITextFieldDelegate

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
}
