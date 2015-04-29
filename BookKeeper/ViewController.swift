//
//  ViewController.swift
//  BookKeeper
//
//  Created by Marc Boanas on 27/04/2015.
//  Copyright (c) 2015 Marc Boanas. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var activityIndictorView: UIView!
    
    let httpHelper = HTTPHelper()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndictorView.layer.cornerRadius = 10
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func loginButtonPressed(sender: UIButton) {
        //resign the keyboard for text fields
        if emailTextField.isFirstResponder() {
            emailTextField.resignFirstResponder()
        }
        if passwordTextField.isFirstResponder() {
            passwordTextField.resignFirstResponder()
        }
        //display activity indicator
        activityIndictorView.hidden = false
        // validate presence of required parameters
        if countElements(emailTextField.text) > 0 && countElements(passwordTextField.text) > 0 {
            makeSignInRequest(emailTextField.text, userPassword: passwordTextField.text)
        } else {
            displayAlertMessage("Parameters Required", alertDescription: "Some of the required parameters are missing")
        }
    }
    
    func updateUserLoggedInFlag() {
        // Update the NSUserDefaults flag
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject("logged In", forKey: "userLoggedI")
        defaults.synchronize()
    }
    
    func saveApiTokenInKeychain(tokenDict:NSDictionary) {
        // Store API AuthToken and AuthToken expiry date in Keychain
        tokenDict.enumerateKeysAndObjectsUsingBlock({ (dictKey, dictObj, stopBool) -> Void in
            var myKey = dictKey as NSString
            var myObj = dictObj as NSString
            
            if myKey == "api_authtoken" {
                KeychainAccess.setPassword(myObj as String, account: "Auth_Token", service: "KeyChainService")
            }
            if myKey == "authtoken_expiry" {
                KeychainAccess.setPassword(myObj as String, account: "Auth_Token_Expiry", service: "KeyChainService")
            }
        })
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func displayAlertMessage(alertTitle:NSString, alertDescription:NSString) -> Void {
        // hide activity indicator and display alert message
        activityIndictorView.hidden = true
        let errorAlert = UIAlertView(title: alertTitle as String, message: alertDescription as String, delegate: nil, cancelButtonTitle: "OK")
        errorAlert.show()
    }
    
    func makeSignInRequest(userEmail:String, userPassword:String) {
        // Create HTTP request and set request Body
        let httpRequest = httpHelper.buildRequest("signin", method: "POST", authType: HTTPRequestAuthType.HTTPBasicAuth)
        let encryptedPassword = AESCrypt.encrypt(userPassword, password: HTTPHelper.API_AUTH_PASSWORD)
        httpRequest.HTTPBody = "{\"email\":\"\(emailTextField.text)\",\"password\":\"\(encryptedPassword)\"}".dataUsingEncoding(NSUTF8StringEncoding);
        httpHelper.sendRequest(httpRequest, completion: { (data:NSData!, error:NSError!) in
            // Display error
            if error != nil {
                let errorMessage = self.httpHelper.getErrorMessage(error)
                self.displayAlertMessage("Error", alertDescription: errorMessage)
                return
            }
            // Hide activity indicator and update userLoggedInFlag
            self.activityIndictorView.hidden = true
            self.updateUserLoggedInFlag()
            var jsonError:NSError?
            let responseDict = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &jsonError) as NSDictionary
            var stopBool : Bool
            // Save API AuthToken and ExpiryDate in Keychain
            self.saveApiTokenInKeychain(responseDict)
        })
    }
}

