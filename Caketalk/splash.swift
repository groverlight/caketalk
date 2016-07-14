//
//  splash.swift
//  Caketalk
//
//  Created by Grover Light on 5/11/16.
//  Copyright © 2016 Grover Light. All rights reserved.
//

import UIKit
import Player
import AVFoundation

class splash: UIViewController, PlayerDelegate {

    var audioPlayer : AVAudioPlayer!
    
    let videoUrl = NSURL(string: "https://v.cdn.vine.co/r/videos/AA3C120C521177175800441692160_38f2cbd1ffb.1.5.13763579289575020226.mp4")!
    
    private var player: Player!

/*---------------BEGIN OUTLETS 🎛----------------------*/

    @IBOutlet var loginButton: UIButton!
    @IBOutlet var loginEmoji: UILabel!

/*---------------END OUTLETS 🎛----------------------*/


    override func viewDidLoad() {
        super.viewDidLoad()
        print ("login view loaded")
        
        self.player = Player()
        self.player.delegate = self
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
        playSoundWithPath(NSBundle.mainBundle().pathForResource("click_pop", ofType: "wav")!)



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


