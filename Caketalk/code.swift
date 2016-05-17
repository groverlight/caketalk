//
//  code.swift
//  Caketalk
//
//  Created by Grover Light on 5/11/16.
//  Copyright © 2016 Grover Light. All rights reserved.
//

import UIKit
import CloudKit

class code: UIViewController, UITextFieldDelegate {
    var labelCounter = 0

/*---------------BEGIN OUTLETS----------------------*/

    @IBOutlet var oneLabel: UILabel!
    @IBOutlet var twoLabel: UILabel!
    @IBOutlet var threeLabel: UILabel!

    @IBOutlet var codeLabel: UILabel!

    @IBOutlet var digitOne: UILabel!
    @IBOutlet var digitTwo: UILabel!
    @IBOutlet var digitThree: UILabel!
    @IBOutlet var digitFour: UILabel!
    @IBOutlet var digitFive: UILabel!



    @IBOutlet var line: UIView!

    @IBOutlet var hangTightLabel: UILabel!
    @IBOutlet var noCodeButton: UIButton!

    @IBOutlet var invisibleTextField: UITextField!

/*---------------END OUTLETS----------------------*/


    override func viewDidLoad() {
        print ("code view is loaded")
        super.viewDidLoad()
        self.invisibleTextField.delegate = self

/*---------------BEGIN STYLE 🎨----------------------*/

        //rounding edges out use MASKTOBOUNDS=true

    self.oneLabel.layer.cornerRadius = 10
    self.oneLabel.clipsToBounds = true
    self.twoLabel.layer.cornerRadius = 10
    self.twoLabel.clipsToBounds = true
    self.threeLabel.layer.cornerRadius = 10
    self.threeLabel.clipsToBounds = true

    self.digitOne.layer.cornerRadius = 6
    self.digitTwo.layer.cornerRadius = 6
    self.digitThree.layer.cornerRadius = 6
    self.digitFour.layer.cornerRadius = 6
    self.digitFive.layer.cornerRadius = 6

/*---------------END STYLE 🎨----------------------*/

}

    override func viewDidAppear(animated: Bool) {
        invisibleTextField.performSelector(#selector(UIResponder.becomeFirstResponder), withObject: nil, afterDelay: 0)
        labelCounter = 0
    }
    override func viewWillDisappear(animated: Bool) {
        self.invisibleTextField.resignFirstResponder()
    }
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        //print ("\(textField.text!)\(string)")
        var newDigit:UILabel!

        if (range.length == 0){
            //print ("morechar")
            labelCounter += 1
        }
        switch labelCounter{
        case 1 :
            newDigit = digitOne
            break
        case 2 :
            newDigit = digitTwo
            break
        case 3 :
            newDigit = digitThree
            break
        case 4 :
            newDigit = digitFour
            break
        case 5 :
            newDigit = digitFive
            break
        default:
            return false
        }
        if (range.length == 0){
            newDigit.text = string
        }
        else if (range.length == 1){
            //print ("lesschar")
            newDigit.text = ""
            labelCounter -= 1
        }
        // print (newDigit)
        if (labelCounter == 5){
            digitFive.text = string
            // let animation = MAActivityIndicatorView(frame: self.view.bounds)
            if ( codeFired == textField.text! + string){
                // NSNotificationCenter.defaultCenter().postNotificationName("move", object: nil)

                //self.dismissViewControllerAnimated(true, completion: nil)
               // let delay = 1 * Double(NSEC_PER_SEC)
                //let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
                //dispatch_after(time, dispatch_get_main_queue()) {
                dispatch_async(dispatch_get_main_queue()) {
                    let prefs = NSUserDefaults.standardUserDefaults()
                    prefs.setValue("didLogin", forKey: "Login")
                    self.performSegueWithIdentifier("finishLogin", sender: self)



                }
            }
            else {
                let wrongCode = UIAlertController(title: "Wrong Code Bruh", message: "Looks like the verification code was incorrect. Please Try Again.", preferredStyle: UIAlertControllerStyle.Alert)
                let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction!) in
                    NSNotificationCenter.defaultCenter().postNotificationName("move", object: nil)
                })
                wrongCode.addAction(okAction)
                dispatch_async(dispatch_get_main_queue()) {
                    self.invisibleTextField.text = ""
                    self.digitOne.text = "•"
                    self.digitTwo.text = "•"
                    self.digitThree.text = "•"
                    self.digitFour.text = "•"
                    self.digitFive.text = "•"
                    self.presentViewController(wrongCode, animated: true, completion: nil)
                }
            }
            
        }
        
        
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    //Mark: blah blah blah


}
