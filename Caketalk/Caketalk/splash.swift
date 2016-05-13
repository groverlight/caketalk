//
//  splash.swift
//  Caketalk
//
//  Created by Grover Light on 5/11/16.
//  Copyright © 2016 Grover Light. All rights reserved.
//

import UIKit

class splash: UIViewController {

/*---------------BEGIN OUTLETS----------------------*/

    @IBOutlet var loginButton: UIButton!
    @IBOutlet var loginEmoji: UILabel!

/*---------------END OUTLETS----------------------*/



    override func viewDidLoad() {
        super.viewDidLoad()
        print ("login view loaded")

/*---------------BEGIN STYLE 🎨----------------------*/


self.loginButton.layer.cornerRadius = 6


/*---------------END STYLE 🎨----------------------*/


}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }
    

//MARK: This function calls permission priming

    @IBAction func loginButtonPressed(sender: AnyObject) {
        print("login button pressed")

    }


}
