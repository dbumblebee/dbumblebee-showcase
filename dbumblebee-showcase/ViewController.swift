//
//  ViewController.swift
//  dbumblebee-showcase
//
//  Created by Brian Bresen on 11/21/16.
//  Copyright © 2016 BeeHive Productions. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import Firebase

class ViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if UserDefaults.standard.value(forKey: KEY_UID) != nil {
            self.performSegue(withIdentifier: SEGUE_LOGGED_IN, sender: nil)
        }
    }

    @IBAction func fbBtnPressed(sender: UIButton!) {
        let facebookLogin = FBSDKLoginManager()
      
        facebookLogin.logIn(withReadPermissions: ["email"], from: self) { (facebookResult, facebookError) in
            
            if facebookError != nil {
                print("Facebook login failed. Error \(facebookError)")
                print("Result is: \(facebookResult)")
            } else {
                let accessToken = FBSDKAccessToken.current().tokenString
                print("Successfully logged in with facebook. \(accessToken)")
                let credential = FIRFacebookAuthProvider.credential(withAccessToken: accessToken!)
                
                FIRAuth.auth()?.signIn(with: credential) { (user, error) in

                    if error != nil {
                        print("Login Failed! \(error)")
                    } else {
                        print("Logged In! \(credential.provider) \(user?.uid)")
                        
                        //We should really only do this if it doesn't exist so we don't 
                        //delete any user data. so i adjusted createFirebaseUser 
                        // to use updateChildValues instead of setValue to avoid overwrite
                        let userData = ["provider": credential.provider]
//                        let userData = ["username": user?.displayName]
                        DataService.ds.createFirebaseUser(uid: (user?.uid)!, user: userData as! Dictionary<String, String>)
                        
                        UserDefaults.standard.set(user?.uid, forKey: KEY_UID)
                        self.performSegue(withIdentifier: SEGUE_LOGGED_IN, sender: nil)
                    }
                }
            }
        }
    }
    
    @IBAction func attemptLogin(sender: UIButton!) {
        if let email = emailField.text, email != "", let pwd = passwordField.text, pwd != "" {
            FIRAuth.auth()?.signIn(withEmail: email, password: pwd) { user, error in
                if let error = error as? NSError {
                    print(error)
                    print(error.localizedDescription)
                    
                    if error.code == STATUS_ACCOUNT_NONEXIST {
                        FIRAuth.auth()?.createUser(withEmail: email, password: pwd) { user, error in
                            if let createError = error as? NSError {
                                if createError.code == STATUS_PASSWORD_SHORT {
                                    self.showErrorAlert(title: "Could not create account", msg: "Password must be at least six characters")
                                }
                                print(createError)
                                self.showErrorAlert(title: "Could not create account", msg: "Problem creating account. Try something else")
                            } else {
                                UserDefaults.standard.set(user?.uid, forKey: KEY_UID)
                                FIRAuth.auth()?.signIn(withEmail: email, password: pwd) { user, error in
                                    let userData = ["provider": user?.providerID]
                                    DataService.ds.createFirebaseUser(uid: (user?.uid)!, user: userData as! Dictionary<String, String>)
                                }
                                self.performSegue(withIdentifier: SEGUE_LOGGED_IN, sender: nil)
                            }
                        }
                    } else if error.code == STATUS_PASSWORD_INVALID {
                        self.showErrorAlert(title: "Could not login.", msg: "Invalid username or password")
                    } else {
                        self.showErrorAlert(title: "Could not login.", msg: "Please check username or password")
                    }
                } else {
                    UserDefaults.standard.set(user?.uid, forKey: KEY_UID)
                    self.performSegue(withIdentifier: SEGUE_LOGGED_IN, sender: nil)
                }
            }
        } else {
            showErrorAlert(title: "Email and Password Required", msg: "You must enter an email and a password")
        }
    }
    
    func showErrorAlert(title: String, msg: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
}

