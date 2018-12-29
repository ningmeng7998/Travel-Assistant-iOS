//
//  LoginViewController.swift
//  TravelAssistant
//
//  Created by ning li on 13/10/18.
//  Copyright © 2018 ning li. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseAuth

class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    var handle: AuthStateDidChangeListenerHandle?

    
    @IBAction func registerButton(_ sender: Any) {
        //Create user
        Auth.auth().createUser(withEmail: emailTextField.text!,
                                   password: passwordTextField.text!)
        { (user, error) in
            if error == nil {
                // Log the user in
                Auth.auth().signIn(withEmail: self.emailTextField.text!,
                                       password: self.passwordTextField.text!)
                { (user, error) in
                    //  Create new user in database
                    let uid = (Auth.auth().currentUser?.uid)!
                    let ref = Database.database().reference()
                    // Initialise the user data structure in firebase
                    self.readJson()
                    var dict = [String: Any]()
                    dict["email"] = self.emailTextField.text!
                    ref.child(uid).child("personalInfo").updateChildValues(dict)
                    self.performSegue(withIdentifier: "registerSegue", sender: self)
                }
            } else {
                self.dispalyErrorMessage(errorMessage: error!.localizedDescription)
            }
        }
    }
    
    // Firebase user initialization file
    func readJson() {
        let uid = (Auth.auth().currentUser?.uid)!
        let ref = Database.database().reference()
        
        do {
            if let file = Bundle.main.url(forResource: "initial", withExtension: "json") {
                let data = try Data(contentsOf: file)
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if let object = json as? [String: Any] {
                    // json is a dictionary
                    print("object is \(object)")
                    
                    ref.child(uid).updateChildValues(object)
                } else if let object = json as? [Any] {
                    // json is an array
                    print(object)
                } else {
                    print("JSON is invalid")
                }
            } else {
                print("no file")
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    
    
    @IBAction func loginButton(_ sender: Any) {
        //Do some validation on the email and password
        guard let password = passwordTextField.text else{
            dispalyErrorMessage(errorMessage: "Please enter a password")
            return
        }
        
        guard let email = emailTextField.text else{
            dispalyErrorMessage(errorMessage: "Please enter an email")
            return
        }
        
        //Sign in the user with firebase
        Auth.auth().signIn(withEmail:email , password: password) { (user, error) in
            if error != nil{
                self.dispalyErrorMessage(errorMessage: error!.localizedDescription)
            }else{
                self.performSegue(withIdentifier: "loginSegue", sender: nil)
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    //Error message
    func dispalyErrorMessage(errorMessage: String){
        let alertController = UIAlertController(title: "Error", message: errorMessage, preferredStyle: UIAlertController.Style.alert)
        
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default, handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }

}
