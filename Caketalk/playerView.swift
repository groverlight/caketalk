//
//  playerView.swift
//  Caketalk
//
//  Created by Grover Light on 5/11/16.
//  Copyright © 2016 Grover Light. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import UIKit
import GPUImage
import Social
import Accounts
import pop
import AVFoundation
import Mixpanel
import AssetsLibrary
import FBSDKShareKit
//import FBSDKCoreKit
//import FBSDKLoginKit
import Photos
import MobileCoreServices
import EasyTipView

class playerView: UIViewController,/*FBSDKSharingDelegate,*/ UIScrollViewDelegate, EasyTipViewDelegate, FBSDKSharingDelegate {
    var audioPlayer : AVAudioPlayer!
    var moviePlayer: AVPlayer?
    var numOfClips = 0
    var totalReceivedClips = 0
    var fileManager: NSFileManager? = NSFileManager()
    var labelFont: UIFont?
    var overlay: UIVisualEffectView?
    var didPlay = false
    var showStatusBar = false
    var gradientView:GradientView = GradientView()
    
    let mixPanel : Mixpanel! = Mixpanel.sharedInstance()

    @IBOutlet var facebookButtonHeight : NSLayoutConstraint!
    @IBOutlet var instagramButtonHeight : NSLayoutConstraint!
    @IBOutlet var twitterButtonHeight : NSLayoutConstraint!
    @IBOutlet var moreButtonHeight : NSLayoutConstraint!

/*---------------BEGIN OUTLETS----------------------*/

    @IBOutlet var progressBarView: UIView!
    @IBOutlet var animatedProgressBarView: UIView!

    @IBOutlet var line: UIView!
    @IBOutlet var headerView: UIView!
    @IBOutlet var headerLabel: UILabel!

    @IBOutlet var movieView: UIView!
    @IBOutlet var label: UILabel!

    @IBOutlet var facebookButton: UIImageView!
    @IBOutlet var twitterButton: UIImageView!
    @IBOutlet var instagramButton: UIImageView!
    @IBOutlet var moreButton: UIImageView!

    @IBOutlet var backButton: UIButton!
    @IBOutlet var backEmoji: UILabel!

/*---------------END OUTLETS----------------------*/

    func setupVideo(index: Int){

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(playerView.playerItemDidReachEnd(_:)), name:AVPlayerItemDidPlayToEndTimeNotification, object: nil);

        let avAsset = AVAsset(URL: NSURL.fileURLWithPath("\(NSTemporaryDirectory())\(index).mov"))
        print("index: \(index)")
        let avPlayerItem = AVPlayerItem(asset: avAsset)
        moviePlayer = AVPlayer(playerItem: avPlayerItem)
        let avLayer = AVPlayerLayer(player: moviePlayer)
        avLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        avLayer.frame = CGRectMake(0, 100, self.view.bounds.size.width, self.view.bounds.size.height - 200)
        self.movieView.layer.addSublayer(avLayer)
        self.moviePlayer?.play()
        self.view.bringSubviewToFront(self.gradientView)
        let scrollLabel = PaddingLabel()

        //height of where player label starts
        scrollLabel.frame = CGRectMake(20,self.view.bounds.size.height*0.50, self.view.bounds.size.width*(2/3)-20,50)

        scrollLabel.textColor = UIColor.whiteColor()
        print (scrollLabel.frame)
        scrollLabel.font = labelFont
        scrollLabel.text = (arrayofText.objectAtIndex(index-1) as! String)
        print (scrollLabel.text)
        scrollLabel.numberOfLines = 0
        scrollLabel.sizeToFit()
        scrollLabel.layer.cornerRadius = 10
        scrollLabel.layer.masksToBounds = true
        scrollLabel.backgroundColor = randomColor(hue: .Random, luminosity: .Light).colorWithAlphaComponent(0.70)

        scrollLabel.setLineHeight(0)
        self.view.addSubview(scrollLabel)

        let animation: POPBasicAnimation = POPBasicAnimation(propertyNamed: kPOPLayerPositionY)

        animation.duration = CMTimeGetSeconds(avAsset.duration) + 4.25
        animation.repeatCount = 0
        animation.autoreverses = false
        animation.toValue = self.view.bounds.size.height/3 - scrollLabel.bounds.size.height
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionLinear)


        let animation3 = POPSpringAnimation(propertyNamed: kPOPLayerScaleXY)
        animation3.toValue = NSValue(CGPoint: CGPointMake(1, 1))
        animation3.velocity = NSValue(CGPoint: CGPointMake(6, 6))
        animation3.springBounciness = 20.0
        animation3.beginTime = AVCoreAnimationBeginTimeAtZero
        animation3.repeatCount = 0
        animation3.autoreverses = false
        let animation4 = POPBasicAnimation(propertyNamed: kPOPLayerOpacity)
        animation4.duration = 0.00000001
        animation4.repeatCount = 0
        animation4.beginTime = AVCoreAnimationBeginTimeAtZero
        animation4.autoreverses = false
        animation4.fromValue = 0.0
        animation4.toValue = 1.0
        animation4.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionLinear)

        // animation4.removedOnCompletion = true
        animation4.completionBlock = {(animation,finished) in
            let animation2: POPBasicAnimation = POPBasicAnimation(propertyNamed: kPOPLayerOpacity)
            animation2.duration = CMTimeGetSeconds(avAsset.duration) + 4.25
            animation2.repeatCount = 0
            animation2.autoreverses = false
            animation2.toValue = 0
            animation2.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionLinear)
            scrollLabel.layer.pop_addAnimation(animation2, forKey: "goDisappear")
        }

        scrollLabel.layer.pop_addAnimation(animation, forKey: "goUP")
        scrollLabel.layer.pop_addAnimation(animation3, forKey: "spring)")
        scrollLabel.layer.pop_addAnimation(animation4, forKey: "goAppear)")

        numOfClips -= 1

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        backButton.layer.cornerRadius = 6
        gradientView.frame = self.view.bounds
        gradientView.backgroundColor = UIColor.clearColor()
        gradientView.colors = [UIColor.clearColor(), UIColor.blackColor()]
        gradientView.locations = [0, 1]
        gradientView.direction = .Vertical
        gradientView.alpha = 0.8
        
        // make gradient a subview

        self.view.insertSubview(self.gradientView, aboveSubview: self.movieView)

    }

    override func viewWillAppear(animated: Bool) {
        self.view.bringSubviewToFront(movieView)
        self.view.bringSubviewToFront(self.progressBarView)
        do{
            let String = "MediaCache"
            try self.fileManager?.removeItemAtPath("\(NSTemporaryDirectory())\(String)")        }
        catch{
        }
        do{
            let files = try self.fileManager?.contentsOfDirectoryAtPath(NSTemporaryDirectory())
            print (files)
            numOfClips = arrayofText.count
            totalReceivedClips = numOfClips
            print (numOfClips) // last where I Started
            //print (files)
        }
        catch {
        }

        facebookButton.hidden = true
        twitterButton.hidden = true
        instagramButton.hidden = true
        moreButton.hidden = true
        backButton.hidden = true
        backEmoji.hidden = true


        iPhoneScreenSizes()
        if (didPlay == false){
            self.moviePlayer?.seekToTime(kCMTimeZero)
            self.moviePlayer?.volume = 0.0
            self.moviePlayer?.actionAtItemEnd = AVPlayerActionAtItemEnd.None
            self.setupVideo(1)

        }
        var duration: CFTimeInterval = 0


        for i in 0..<arrayofText.count{
            let avAsset = AVAsset(URL: NSURL.fileURLWithPath("\(NSTemporaryDirectory())\(i+1).mov"))
            duration = duration + CMTimeGetSeconds(avAsset.duration)
        }

        self.animatedProgressBarView.transform = CGAffineTransformMakeScale(1, 1)
        if (didPlay == false){





            self.progressBarView.hidden = false
            self.view.bringSubviewToFront(self.headerView)
            self.view.bringSubviewToFront(self.progressBarView)
            self.view.bringSubviewToFront(self.animatedProgressBarView)

            print (duration)
            UIView.animateWithDuration(duration) { () -> Void in
                self.animatedProgressBarView.transform = CGAffineTransformMakeScale(0.000001, 1)
            }
        }
    }

    override func prefersStatusBarHidden() -> Bool {
        if showStatusBar {
            return false
        }
        return true
    }

    private func showStatusBar(enabled: Bool) {
        showStatusBar = enabled
        self.setNeedsStatusBarAppearanceUpdate()
        //prefersStatusBarHidden()
    }

    func playerItemDidReachEnd(notification: NSNotification){

        NSNotificationCenter.defaultCenter().removeObserver(self)

        if (numOfClips > 0){
            let clipsLeft = totalReceivedClips - numOfClips + 1
            setupVideo(clipsLeft)
        }
        else{


            overlay = UIVisualEffectView()
            let blurEffect = UIBlurEffect(style: .Dark)
            let overlayScrollView = UIScrollView(frame: CGRectMake(20,40+self.headerView.bounds.size.height,self.view.bounds.size.width-20,2*self.view.bounds.height/3))
            overlayScrollView.showsVerticalScrollIndicator = true
            overlayScrollView.indicatorStyle = UIScrollViewIndicatorStyle.White
            overlayScrollView.userInteractionEnabled = true
            overlayScrollView.scrollEnabled = true
            overlayScrollView.delegate = self

            var scrollHeightOverlay:CGFloat = 0.0
            let arrayofBorders = NSMutableArray()
            for text in arrayofText{


                let newerLabel = UILabel(frame: CGRectMake(6, scrollHeightOverlay, self.view.bounds.size.width*(2/3)-20, 25))
                newerLabel.font =  self.labelFont
                newerLabel.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.4)
                newerLabel.text = text as? String
                newerLabel.numberOfLines = 0
                newerLabel.sizeToFit()
                overlayScrollView.addSubview(newerLabel)

                let border = CALayer()
                border.frame = CGRectMake(0 , scrollHeightOverlay + 45 + self.headerView.bounds.size.height, 4, CGRectGetHeight(newerLabel.frame)-12)
                border.backgroundColor = UIColor(red: 85/255, green: 172/255, blue: 238/255, alpha: 1.0).CGColor

                arrayofBorders.addObject(border)
                scrollHeightOverlay = scrollHeightOverlay + newerLabel.bounds.size.height + 10

            }

            // dark, burred view attributes

            overlayScrollView.contentSize = CGSizeMake(self.view.bounds.size.width-20,scrollHeightOverlay)
            let timeStampLabel = UILabel(frame: CGRectMake(6, overlayScrollView.contentSize.height , self.view.bounds.size.width*(2/3)-20,25))
            timeStampLabel.font = UIFont(name:"RionaSans-Bold", size: 10.0)
            timeStampLabel.textColor = UIColor.whiteColor() .colorWithAlphaComponent(0.4)
            timeStampLabel.text = "now"
            timeStampLabel.numberOfLines = 0
            timeStampLabel.sizeToFit()
            overlayScrollView.addSubview(timeStampLabel)
            let emojiLabel = UILabel(frame: CGRectMake(6, overlayScrollView.contentSize.height+16, self.view.bounds.size.width*(2/3)-20,25))
            emojiLabel.font = UIFont(name:"Avenir Next", size:14)
            emojiLabel.textColor = UIColor.whiteColor()
            emojiLabel.text = "👁"
            emojiLabel.numberOfLines = 0
            timeStampLabel.sizeToFit()
            overlayScrollView.addSubview(emojiLabel)
            showStatusBar(true)

            
            self.facebookButtonHeight.constant = -200
            self.instagramButtonHeight.constant = -200
            self.twitterButtonHeight.constant = -200
            self.moreButtonHeight.constant = -200

            overlay!.frame = self.view.bounds
            self.view.addSubview(overlay!)
            UIView.animateWithDuration(1.5, animations: {self.overlay!.effect = blurEffect}, completion: { finished in
                self.headerView.backgroundColor = UIColor(red: 85/255, green: 172/255, blue: 238/255, alpha: 1.0)
                self.headerLabel.text = "share"
                for border in arrayofBorders{
                    self.overlay!.layer.addSublayer(border as! CALayer)
                }
                self.backButton.transform = CGAffineTransformMakeTranslation(0, 2000)
                self.backEmoji.transform = CGAffineTransformMakeTranslation(0, 2000)
                self.view.addSubview(overlayScrollView)
                self.view.bringSubviewToFront(overlayScrollView)
                self.view.bringSubviewToFront(self.backButton)
                self.view.bringSubviewToFront(self.backEmoji)
                self.view.bringSubviewToFront(self.facebookButton)
                self.view.bringSubviewToFront(self.twitterButton)
                self.view.bringSubviewToFront(self.instagramButton)
                self.view.bringSubviewToFront(self.moreButton)
                self.view.bringSubviewToFront(self.headerView)
                self.facebookButton.hidden = false
                self.twitterButton.hidden = false
                self.instagramButton.hidden = false
                self.moreButton.hidden = false
                self.backButton.hidden = false
                self.backEmoji.hidden = false
                
                self.facebookButton.userInteractionEnabled = true
                self.twitterButton.userInteractionEnabled = true
                self.instagramButton.userInteractionEnabled = true
                self.moreButton.userInteractionEnabled = true
                
                let handleFacebook = UITapGestureRecognizer(target: self, action: #selector(playerView.facebook))
                self.facebookButton.addGestureRecognizer(handleFacebook)
                
                let handleTwitter = UITapGestureRecognizer(target: self, action: #selector(playerView.twitter))
                self.twitterButton.addGestureRecognizer(handleTwitter)
                
                let handleInstagram = UITapGestureRecognizer(target: self, action: #selector(playerView.instagram))
                self.instagramButton.addGestureRecognizer(handleInstagram)
                
                let handleMore = UITapGestureRecognizer(target: self, action: #selector(playerView.share))
                self.moreButton.addGestureRecognizer(handleMore)
                
                self.facebookButtonHeight.constant = 50
                UIView.animateWithDuration(0.8, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.1, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
                    self.view.layoutIfNeeded()
                    }, completion: {  finished in
                })
                
                self.twitterButtonHeight.constant = 50
                UIView.animateWithDuration(0.8, delay: 0.1, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.1, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
                    self.view.layoutIfNeeded()
                    }, completion: {  finished in
                })
                
                self.instagramButtonHeight.constant = 50
                UIView.animateWithDuration(0.8, delay: 0.2, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.1, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
                    self.view.layoutIfNeeded()
                    }, completion: {  finished in
                })
                
                self.moreButtonHeight.constant = 50
                UIView.animateWithDuration(0.8, delay: 0.3, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.1, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
                    self.view.layoutIfNeeded()
                    }, completion: {  finished in
                })
                
                
                UIView.animateWithDuration(0.5, animations: {() -> Void in
                    self.backButton.transform = CGAffineTransformMakeTranslation(0, 0)
                    self.backEmoji.transform = CGAffineTransformMakeTranslation(0, 0)
                    }, completion: { finished in

                })

                self.view.bringSubviewToFront(self.line)
                self.line.hidden = false
                
                                if NSUserDefaults.standardUserDefaults().objectForKey("isFirstLaunch-line") == nil {
                                        // EasyTipView global preferences
                                        var preferences = EasyTipView.Preferences()
                                        preferences.drawing.font = UIFont(name: "Futura-Medium", size: 16)!
                                        preferences.drawing.foregroundColor = UIColor.blackColor()
                                        preferences.drawing.backgroundColor = UIColor.hex("#FFEAC2")
                                        preferences.drawing.arrowPosition = EasyTipView.ArrowPosition.Bottom
                                        preferences.animating.showDuration = 2
                                        EasyTipView.show(forView: self.line,
                                            withinSuperview: self.view,
                                            text: "Share it on the web",
                                            preferences: preferences,
                                            delegate: self)
                                        
                                        NSUserDefaults.standardUserDefaults().setObject(false, forKey: "isFirstLaunch-line")
                                    }

            })
            
        }
        
    }
    
    func iPhoneScreenSizes(){
        let bounds = UIScreen.mainScreen().bounds
        let height = bounds.size.height

        switch height {
        case 480.0:
            //print("iPhone 3,4")
            labelFont = UIFont(name: "RionaSans-Bold", size: 19)
        case 568.0:
            //print("iPhone 5")
            labelFont = UIFont(name: "RionaSans-Bold", size: 20)
        case 667.0:
            //print("iPhone 6")
            labelFont = UIFont(name: "RionaSans-Bold", size: 21)
        case 736.0:
            //print("iPhone 6+")
            labelFont = UIFont(name: "RionaSans-Bold", size: 22 )
        default:
            break
            //print("not an iPhone")

        }

    }

        // Do any additional setup after loading the view.


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: EasyTipViewDelegate
    func easyTipViewDidDismiss(tipView : EasyTipView) {
    
    }
    

//MARK: This clears draft and takes you back
    

    @IBAction func backButtonPressed(sender: AnyObject) {
         print("back button pressed")
         print("SOUND EFFECT HERE")
         print("Mixpanel event here")
        
        mixPanel.track("Player back button pressed");
        mixPanel.flush()
        
        playSoundWithPath(NSBundle.mainBundle().pathForResource("chime_dim", ofType: "aif")!)

        arrayofText.removeAllObjects()
        do {
            let files = try self.fileManager?.contentsOfDirectoryAtPath(NSTemporaryDirectory())
            for file:NSString in files!{
                try self.fileManager?.removeItemAtPath("\(NSTemporaryDirectory())\(file)")
            }


        }
        catch {
        }
        dispatch_async(dispatch_get_main_queue()) {
            self.dismissViewControllerAnimated(false, completion: nil)
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
    
    func twitter() {
        
        self.backButton.setTitle("another one", forState: .Normal)
        self.backButton.layer.cornerRadius = 6
        self.backEmoji.text = "👔"
        self.backEmoji.hidden = false
        
        let alertController = UIAlertController(title: "Twitter Video sharing", message: "Enter your tweet", preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "#cakeTalk"
        }
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
            //Just dismiss the action sheet
        }
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction!) in
            let outputPath = NSURL(fileURLWithPath: "\(NSTemporaryDirectory())edited_video.mov")
            let videoData = NSData(contentsOfURL: outputPath)
            // if (SocialVideoHelper.userHasAccessToTwitter()){
            let accountStore = ACAccountStore()
            let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
            
            
            accountStore.requestAccessToAccountsWithType(accountType, options: nil) { granted, error in
                if (granted){
                    guard let tweetAcc = accountStore.accountsWithAccountType(accountType) where !tweetAcc.isEmpty else {
                        print("There are no Twitter accounts configured. You can add or create a Twitter account in Settings.")
                        return
                    }
                    let twitAccount = tweetAcc[0] as! ACAccount
                    print (twitAccount)
                    let textfield = alertController.textFields![0] as UITextField
                    SocialVideoHelper.uploadTwitterVideo(videoData,comment:textfield.text,account: twitAccount, withCompletion: nil)
                }
                else{
                    print (error)
                }
                
                
                
                
                
            }
            
        })
        
        
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        dispatch_async(dispatch_get_main_queue()) {
            self.presentViewController(alertController, animated: true, completion: nil)
        }
        
        
    }
    
    func instagram() {
        self.backButton.setTitle("another one", forState: .Normal)
        
        // REFERENCE: http://stackoverflow.com/questions/20017266/posting-video-on-instagram-using-hooks/21888830#21888830
        
        ALAssetsLibrary().writeVideoAtPathToSavedPhotosAlbum(NSURL(fileURLWithPath: "\(NSTemporaryDirectory())edited_video.mov"), completionBlock: { (path:NSURL!, error:NSError!) -> Void in
            let asset = AVAsset(URL: path)
            print("Duration:\(asset.duration.seconds)")
            let instagramURL = NSURL(string:  "instagram://library")
            if(UIApplication.sharedApplication().canOpenURL(instagramURL!)) {
                UIApplication.sharedApplication().openURL(instagramURL!)
            } else {
                print("can't open this URL")
            }
        })
    }
    
    func video(video: NSString, didFinishSavingWithError error:NSError, contextInfo:UnsafeMutablePointer<Void>){
        print("saved")
        let instagramURL = NSURL(string:  "instagram://library?AssetPath=\(video)" )
        // if(UIApplication.sharedApplication().canOpenURL(instagramURL!)){
        UIApplication.sharedApplication().openURL(instagramURL!)
        //}
        
    }
    
    
    @IBAction func share() {
        self.backButton.setTitle("another one", forState: .Normal)
        let outputPath = NSURL.fileURLWithPath("\(NSTemporaryDirectory())edited_video.mov")
        let objectsToShare = [outputPath]
        
        let activityViewController  = UIActivityViewController(activityItems:objectsToShare as [AnyObject], applicationActivities: nil)
        
        presentViewController(activityViewController, animated: true, completion: nil)
        
        
    }
    
    func facebook() {
        self.backButton.setTitle("another one", forState: .Normal)
        
        let video : FBSDKShareVideo = FBSDKShareVideo()
        
        ALAssetsLibrary().writeVideoAtPathToSavedPhotosAlbum(NSURL(fileURLWithPath: "\(NSTemporaryDirectory())edited_video.mov"), completionBlock: { (path:NSURL!, error:NSError!) -> Void in
            //let asset = AVAsset(URL: path)
            video.videoURL = path
            let content : FBSDKShareVideoContent = FBSDKShareVideoContent()
            content.video = video
            
            let dialog = FBSDKShareDialog()
            let newURL = NSURL(string: "fbauth2://")
            if (UIApplication.sharedApplication() .canOpenURL(newURL!)){
                print("native")
                dialog.mode = FBSDKShareDialogMode.ShareSheet
            }
            else{
                print("browser")
                dialog.mode = FBSDKShareDialogMode.Browser
            }
            
            dialog.shareContent = content;
            dialog.delegate = self;
            dialog.fromViewController = self;
            dialog.show()
        })
        
    }
    
    func sharer(sharer: FBSDKSharing!, didFailWithError error: NSError!) {
        print(error)
    }
    
    func sharer(sharer: FBSDKSharing!, didCompleteWithResults results: [NSObject : AnyObject]!) {
        print("did complete")
    }
    
    func sharerDidCancel(sharer: FBSDKSharing!) {
        
    }
    

}

extension UILabel {

    func setLineHeight(lineHeight: CGFloat) {
        let text = self.text
        if let text = text {
            let attributeString = NSMutableAttributedString(string: text)
            let style = NSMutableParagraphStyle()
            style.lineHeightMultiple = 0.9
            style.lineSpacing = lineHeight
            attributeString.addAttribute(NSParagraphStyleAttributeName, value: style, range: NSMakeRange(0, text.characters.count))
            self.attributedText = attributeString
        }
    }
}

