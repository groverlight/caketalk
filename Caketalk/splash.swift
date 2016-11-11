//
//  splash.swift
//  Caketalk
//
//  Created by Grover Light on 5/11/16.
//  Copyright © 2016 Grover Light. All rights reserved.
//

import UIKit
import Player
import pop
import AVFoundation
import Mixpanel


class splash: UIViewController  {
    

    let videoUrl = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("spalsh_vid", ofType: "mov")!)
    

    private var player: Player!

    var audioPlayer : AVAudioPlayer!
    var mixPanel : Mixpanel!




/*---------------BEGIN OUTLETS 🎛----------------------*/

    @IBOutlet var loginButton: UIButton!
    @IBOutlet var loginEmoji: UILabel!
    @IBOutlet weak var blurVid: UIImageView!

/*---------------END OUTLETS 🎛----------------------*/


    override func viewDidLoad() {
        super.viewDidLoad()
        print ("login view loaded")

        self.player = Player()
        //self.player.delegate = self
        self.player.view.frame = self.view.bounds
        self.player.view.backgroundColor = .clearColor()
        self.addChildViewController(self.player)
        self.view.addSubview(self.player.view)
        self.view.sendSubviewToBack(self.player.view)
        self.player.didMoveToParentViewController(self)
        
        self.player.setUrl(videoUrl)
        
        self.player.playbackLoops = true
        self.player.muted = true
        self.player.playFromBeginning()

        let opacityOutAnimation: POPBasicAnimation = POPBasicAnimation(propertyNamed: kPOPLayerOpacity)
        opacityOutAnimation.duration = 3.5
        opacityOutAnimation.autoreverses = false
        opacityOutAnimation.toValue = 0
        blurVid.layer.pop_addAnimation(opacityOutAnimation, forKey: "opacityOutAnimation")
        
        

        let buttonSpring = POPSpringAnimation(propertyNamed: kPOPViewScaleXY)
        let buttonSpring2 = POPSpringAnimation(propertyNamed: kPOPViewScaleXY)
        buttonSpring.toValue = NSValue(CGPoint: CGPointMake(1, 1))
        buttonSpring.velocity = NSValue(CGPoint: CGPointMake(6, 6))
        buttonSpring.springBounciness = 20.0
        buttonSpring2.toValue = NSValue(CGPoint: CGPointMake(1, 1))
        buttonSpring2.velocity = NSValue(CGPoint: CGPointMake(6, 6))
        buttonSpring2.springBounciness = 20.0

        loginButton.pop_addAnimation(buttonSpring, forKey: "spring")
        loginEmoji.pop_addAnimation(buttonSpring2, forKey: "spring2")

        mixPanel = Mixpanel.sharedInstance()


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

        playSoundWithPath(NSBundle.mainBundle().pathForResource("click_04", ofType: "aif")!)
        audioPlayer.volume = 0.05

        mixPanel.track("login pressed", properties: nil)
        //mixPanel.people .increment("Record button pressed", by: 1)
        mixPanel.identify(mixPanel.distinctId)
        mixPanel.flush()




    }

// MARK: PlayerDelegate
    
    func playerReady(player: Player) {
    
    }
    
    func playerPlaybackStateDidChange(player: Player) {
    
    }
    
    func playerBufferingStateDidChange(player: Player) {
    
    }
    
    func playerPlaybackWillStartFromBeginning(player: Player) {
    
    }
    
    func playerPlaybackDidEnd(player: Player) {
    
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





