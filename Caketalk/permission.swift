//
//  permission.swift
//  Caketalk
//
//  Created by Grover Light on 5/11/16.
//  Copyright © 2016 Grover Light. All rights reserved.
//

import UIKit
import CloudKit
import AVFoundation
import Mixpanel

class permission: UIViewController {
    
    var audioPlayer : AVAudioPlayer!
    var mixPanel : Mixpanel!


/*---------------BEGIN OUTLETS----------------------*/

    @IBOutlet var oneLabel: UILabel!
    @IBOutlet var twoLabel: UILabel!
    @IBOutlet var threeLabel: UILabel!

    @IBOutlet var icloudButton: UIButton!

    @IBOutlet var alertViewTitleLabel: UILabel!

/*---------------END OUTLETS----------------------*/

    override func viewDidLoad() {
        super.viewDidLoad()
        print ("permission view loaded")
        print("SOUND EFFECT HERE")

        mixPanel = Mixpanel.sharedInstance()


        //playSoundWithPath(NSBundle.mainBundle().pathForResource("digi_powerdown", ofType: "aif")!)

/*---------------BEGIN STYLE 🎨----------------------*/

        //rounding edges out

    self.oneLabel.layer.cornerRadius = 10
    self.oneLabel.clipsToBounds = true
    self.twoLabel.layer.cornerRadius = 10
    self.twoLabel.clipsToBounds = true
    self.threeLabel.layer.cornerRadius = 10
    self.threeLabel.clipsToBounds = true


    self.icloudButton.layer.cornerRadius = 6
    self.alertViewTitleLabel.font = UIFont (name: "RionaSans-Bold", size: 17)

/*---------------END STYLE 🎨----------------------*/


}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


//MARK: This function calls the iCloud login & uialertview

    @IBAction func icloudPressed(sender: AnyObject) {
        print("iCloud button pressed")
        print("SOUND EFFECT HERE")
        
        self.icloudButton.setTitle("WAITING ⏳", forState: .Normal)
        self.icloudButton.setTitleColor(UIColor.blackColor() .colorWithAlphaComponent(0.30), forState: .Normal)
        
        playSoundWithPath(NSBundle.mainBundle().pathForResource("click_04", ofType: "aif")!)
        audioPlayer.volume = 0.05

        mixPanel.track("no worries pressed", properties: nil)
        //mixPanel.people .increment("Record button pressed", by: 1)
        mixPanel.identify(mixPanel.distinctId)
        mixPanel.flush()


        //self.alertView.hidden = true
        

        self.iCloudLogin({ (success) -> () in
            if success {

                // print ("success")
            } else {
                ("error")
                // TODO error handling
            }
        })


    }

    private func iCloudLogin(completionHandler: (success: Bool) -> ()) {
        cloudManager.requestPermission { (granted) -> () in
            if !granted {
                dispatch_async(dispatch_get_main_queue()) {
                    self.performSegueWithIdentifier("permissionAsk", sender: self)
                }
            } else {
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.performSegueWithIdentifier("permissionAsk", sender: self)
                }
                
                cloudManager.getUser({ (success, let user) -> () in
                    if success {
                        userFull = user

                        cloudManager.getUserInfo(userFull!, completionHandler: { (success, user) -> () in
                            if success {
                                completionHandler(success: true)
                            }
                        })
                    } else {
                        // TODO error handling
                    }
                })
            }
        }
    }

    func playSoundWithPath(path : String) {
        let url = NSURL(fileURLWithPath: path)
        do{
            audioPlayer = try AVAudioPlayer(contentsOfURL: url)
        }catch _ {
            audioPlayer = nil
        }
        
        audioPlayer.prepareToPlay()
        audioPlayer.play()
    }

}

