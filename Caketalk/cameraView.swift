//
//  cameraView.swift
//  Caketalk
//
//  Created by Grover Light on 5/11/16.
//  Copyright © 2016 Grover Light. All rights reserved.
//

import UIKit
import GPUImage
import pop
import Mixpanel
import Hue
import UIImageColors
import EasyTipView
import AssetsLibrary
import AVFoundation

class cameraView: UIViewController, UITextViewDelegate, UIScrollViewDelegate, EasyTipViewDelegate {
    
    var recording = false
    var audioPlayer : AVAudioPlayer!
    var shouldGoDown = false
    var previousRect = CGRectZero
    var oldKeyboardHeight:CGFloat = 0.0
    var autoCorrectHeight:CGFloat = 0.0
    var imagePicker: UIImagePickerController! = UIImagePickerController()
    var actualOffset:CGPoint = CGPoint()
    var typingButtonFrame : CGRect!
    var scrollCounter:CGFloat = 0.0
    var scrollHeightCounter = 0
    var oldLabel: UILabel?
    var scrollHeight:CGFloat = 0.0
    let captureSession = AVCaptureSession()
    var captureDevice : AVCaptureDevice?
    var previewLayer : AVCaptureVideoPreviewLayer?
    var shouldEdit = true
    var videoCamera:GPUImageVideoCamera?
    var filter:GPUImageExposureFilter?
    var filteredImage: GPUImageView?
    var newImage: GPUImageView?
    var movieWriter: GPUImageMovieWriter?
    var movieComposition: GPUImageMovieComposition?
    var gradientView:GradientView = GradientView()
    var clipCount = 1
    var fileManager: NSFileManager? = NSFileManager()
    var longPressRecognizer: UILongPressGestureRecognizer!
    var showStatusBar = true
    var firstTime = false
    var newOne = true
    var mixPanel : Mixpanel!
    var videoClips : [NSURL]!
    
    var arrayofText: [String] = []
    var arrayOfClipDurations: [Double] = []
    
    var indicatorView: UIView!
    
    var tipView: EasyTipView!
    
    var topVisualEffectView: UIVisualEffectView!
    var bottomVisualEffectView: UIVisualEffectView!


/*---------------BEGIN OUTLETS----------------------*/

    @IBOutlet var progressBarView: UIView!
    @IBOutlet var animatedProgressBarView: UIView!
    @IBOutlet var headerView: UIView!
    @IBOutlet var headerLabel: UILabel!
    @IBOutlet var cameraTextView: UITextView!
    @IBOutlet var recordButton: UIButton!
    @IBOutlet var recordEmoji: UILabel!
    @IBOutlet var characterCount: UILabel!
    @IBOutlet var clearButton: UIButton!
    @IBOutlet var clearEmoji: UILabel!
    @IBOutlet var backButton: UIButton!
    @IBOutlet var backEmoji: UILabel!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var line: UIView!

    //constraints

    @IBOutlet var cameraTextViewBottom: NSLayoutConstraint!
    @IBOutlet var recordButtonBottom: NSLayoutConstraint!
    @IBOutlet var scrollViewBottom: NSLayoutConstraint!
    @IBOutlet var draftBottomSpacing : NSLayoutConstraint!
    
    var coloredBackgroundView : UIView!
    
    var colorSamplingRate : Double = 1
    var screenshotTimer : NSTimer!
    
    dynamic var currentImage : UIImage!
    
    var firstFrameToPassImage: UIImage!

/*---------------END OUTLETS----------------------*/

    //override functions
    override func viewDidLoad() {
        super.viewDidLoad()
        print("camera view loaded")
        print("SOUND EFFECT HERE")

        mixPanel = Mixpanel.sharedInstance()
    
        self.cameraTextView.delegate = self
        self.cameraTextView.text = "What's on your mind? "
        self.cameraTextView.autocapitalizationType = UITextAutocapitalizationType.Words
        self.cameraTextView.textContainer.lineBreakMode = NSLineBreakMode.ByWordWrapping
        
        
        if self.cameraTextView.text == "What's on your mind? " {
            self.cameraTextView.autocapitalizationType = UITextAutocapitalizationType.Sentences
        }

        let backgroundVisualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
        backgroundVisualEffectView.frame = CGRectMake(0, 62, self.view.bounds.size.width, self.view.bounds.size.height - 124)
        self.view.insertSubview(backgroundVisualEffectView, atIndex: 0)

/*---------------BEGIN STYLE 🎨----------------------*/

        //rounding edges out
        self.cameraTextView.contentSize = self.cameraTextView.bounds.size

        self.recordButton.layer.cornerRadius = 6
        self.clearButton.layer.cornerRadius = 6
        self.backButton.layer.cornerRadius = 6

        self.characterCount.clipsToBounds = true
        self.characterCount.layer.masksToBounds = true
        self.characterCount.layer.cornerRadius = characterCount.bounds.size.width/2

        //transparent header

        self.headerView.backgroundColor = UIColor .clearColor()

        //hidden items

        self.recordButton.hidden = true
        self.recordEmoji.hidden = true
        self.characterCount.hidden = true
        self.progressBarView.hidden = true
        self.animatedProgressBarView.hidden = true

        self.backButton.hidden = true
        self.backEmoji.hidden = true
        self.clearButton.hidden = true
        self.clearEmoji.hidden = true
        self.line.hidden = true
        
        self.cameraTextView.textColor = UIColor .blackColor().colorWithAlphaComponent(0.3)

/*---------------END STYLE 🎨----------------------*/


        //other misc. important items

        self.cameraTextView.scrollRangeToVisible(NSMakeRange(0, 0))
        self.cameraTextView.textContainer.lineFragmentPadding = 0
        self.scrollView.contentOffset = CGPoint(x: 0, y: self.scrollView.contentOffset.y+100)

        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(cameraView.longPressed(_:)))
        self.view.addGestureRecognizer(longPressRecognizer)

        typingButtonFrame = recordButton.frame



        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(cameraView.keyboardWillShow(_:)), name:UIKeyboardWillShowNotification, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(cameraView.keyboardWillHide(_:)), name:UIKeyboardWillHideNotification, object: nil);

        if (UIImagePickerController.isCameraDeviceAvailable(UIImagePickerControllerCameraDevice.Front)){
            do{
                let files = try fileManager?.contentsOfDirectoryAtPath(NSTemporaryDirectory())
                for file:NSString in files!{
                    try fileManager?.removeItemAtPath("\(NSTemporaryDirectory())\(file)")
                }
                if (files?.count == 0){
                    clipCount = 1
                }

            }
            catch {

            }
            //instantiating the camera

            filteredImage = GPUImageView()
            videoCamera = GPUImageVideoCamera(sessionPreset: AVCaptureSessionPresetHigh, cameraPosition: .Front)
            videoCamera?.horizontallyMirrorFrontFacingCamera = true
            videoCamera?.frameRate = 30
            videoCamera!.outputImageOrientation = .Portrait
            filteredImage?.fillMode = GPUImageFillModeType.PreserveAspectRatioAndFill
            filteredImage?.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)
            filter = GPUImageExposureFilter()
            videoCamera?.addTarget(filter)
            filter?.addTarget(filteredImage)
            self.view.insertSubview(filteredImage!, atIndex: 1)
            videoCamera?.startCameraCapture()
            movieWriter = GPUImageMovieWriter(movieURL: NSURL.fileURLWithPath("\(NSTemporaryDirectory())movie.mov",isDirectory: true), size: CGSizeMake(self.view.bounds.size.width, self.view.bounds.size.height))
            filter?.addTarget(movieWriter)
            movieWriter?.encodingLiveVideo = true
            movieWriter?.shouldPassthroughAudio = false
            gradientView.frame = CGRectMake(0, 62, self.view.bounds.size.width, self.view.bounds.size.height - 124)
            gradientView.backgroundColor = UIColor.clearColor()
            gradientView.colors = [UIColor.clearColor(), UIColor.blackColor()]
            gradientView.locations = [0, 1]
            gradientView.direction = .Vertical
            gradientView.alpha = 0.5

            // make gradient a subview

            self.view.insertSubview(gradientView, aboveSubview:filteredImage!)
            
            topVisualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
            topVisualEffectView.frame = CGRectMake(0, 0, self.view.bounds.size.width, 62)
            self.view.addSubview(topVisualEffectView)
            
            bottomVisualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
            bottomVisualEffectView.frame = CGRectMake(0, self.view.bounds.size.height - 62, self.view.bounds.size.width, 62)
            self.view.addSubview(bottomVisualEffectView)
            
            
            self.view.bringSubviewToFront(headerView)

        }
        else

        { // for simulator

            self.view.backgroundColor = UIColor.brownColor()
            recordButton.userInteractionEnabled = false
        }
        
        iPhoneScreenSizes()

    
        self.performSelector(#selector(cameraView.showFirstTipView), withObject: nil, afterDelay: 4)
    
    }
    
    func showFirstTipView() {
        
        let view = UIView(frame: CGRectMake(0, 0, 1, 1))
        view.center = CGPointMake(self.view.center.x, self.view.center.y + 65)
        self.view.addSubview(view)
        
        if NSUserDefaults.standardUserDefaults().valueForKey("tip-1") == nil {
        
        var preferences = EasyTipView.Preferences()
        preferences.drawing.font = UIFont(name: "AvenirNext-Medium", size: 14)!
        preferences.drawing.foregroundColor = UIColor.blackColor()
        preferences.drawing.backgroundColor = UIColor.whiteColor()
        preferences.drawing.arrowPosition = EasyTipView.ArrowPosition.Bottom
        preferences.animating.dismissDuration = 0.5
        tipView = EasyTipView(text: "Hi, welcome to Caketalk!", preferences: preferences, delegate: self)
        tipView.show(animated: true, forView: view, withinSuperview: self.view)
        self.performSelector(#selector(cameraView.dismissTipView), withObject: nil, afterDelay: 5)
        self.performSelector(#selector(cameraView.showSecondTipView), withObject: nil, afterDelay: 5)
        NSUserDefaults.standardUserDefaults().setValue(true, forKey: "tip-1")
        }

    
    }
    
    func showSecondTipView() {
        
        let view = UIView(frame: CGRectMake(0, 0, 1, 1))
        view.center = CGPointMake(self.view.center.x, self.view.center.y + 65)
        self.view.addSubview(view)
        
        if NSUserDefaults.standardUserDefaults().valueForKey("tip-2") == nil {
            var preferences = EasyTipView.Preferences()
            preferences.drawing.font = UIFont(name: "AvenirNext-Medium", size: 14)!
            preferences.drawing.foregroundColor = UIColor.blackColor()
            preferences.drawing.backgroundColor = UIColor.whiteColor()
            preferences.drawing.arrowPosition = EasyTipView.ArrowPosition.Bottom
            preferences.animating.dismissDuration = 0.5
            tipView = EasyTipView(text: "Type a thought, opinion, or question like...", preferences: preferences, delegate: self)
            tipView.show(animated: true, forView: view, withinSuperview: self.view)
            self.performSelector(#selector(cameraView.dismissTipView), withObject: nil, afterDelay: 4)
            self.performSelector(#selector(cameraView.showThirdTipView), withObject: nil, afterDelay: 4)

            NSUserDefaults.standardUserDefaults().setValue(true, forKey: "tip-2")
        }
    }
    
    
    func showThirdTipView() {
        
        let view = UIView(frame: CGRectMake(0, 0, 1, 1))
        view.center = CGPointMake(self.view.center.x, self.view.center.y + 65)
        self.view.addSubview(view)
        
        if NSUserDefaults.standardUserDefaults().valueForKey("tip-3") == nil {
            var preferences = EasyTipView.Preferences()
            preferences.drawing.font = UIFont(name: "AvenirNext-Medium", size: 14)!
            preferences.drawing.foregroundColor = UIColor.blackColor()
            preferences.drawing.backgroundColor = UIColor.whiteColor()
            preferences.drawing.arrowPosition = EasyTipView.ArrowPosition.Top
            preferences.animating.dismissDuration = 0.5
            tipView = EasyTipView(text: "i.e. With Donald in charge, we are __________", preferences: preferences, delegate: self)
            tipView.show(animated: true, forView: headerView, withinSuperview: self.view)
            self.performSelector(#selector(cameraView.dismissTipView), withObject: nil, afterDelay: 6)
            
            NSUserDefaults.standardUserDefaults().setValue(true, forKey: "tip-3")
        }
    }
    
    
    
    
    
    
    override func viewWillAppear(animated: Bool) {
        
        self.cameraTextView.delegate = self
        self.cameraTextView.textColor = UIColor .blackColor().colorWithAlphaComponent(0.3)
        self.cameraTextView.text = "What's on your mind? "
        self.cameraTextView.autocapitalizationType = UITextAutocapitalizationType.Words
        self.cameraTextView.textContainer.lineBreakMode = NSLineBreakMode.ByWordWrapping
        
        
        if self.cameraTextView.text == "What's on your mind? " {
            self.cameraTextView.autocapitalizationType = UITextAutocapitalizationType.Sentences
        }

        
        do {
            let files = try fileManager?.contentsOfDirectoryAtPath(NSTemporaryDirectory())
            if (files?.count == 0){
                clipCount = 1
                scrollCounter = 0
                self.cameraTextView.resignFirstResponder()
                self.longPressRecognizer.enabled = false

                self.cameraTextView.returnKeyType = UIReturnKeyType.Default
                self.cameraTextView.becomeFirstResponder()
                
                self.scrollView.contentOffset = CGPoint(x: 0, y: 0)
                for subview in self.scrollView.subviews {
                    if subview is UILabel{
                        subview.removeFromSuperview()
                    }
                }
            }
            else{
                if (self.scrollView.contentOffset == CGPoint(x: 0, y: 0)){
                    self.scrollView.contentOffset = actualOffset
                }

            }

        }

        catch {

        }

        self.view.bringSubviewToFront(recordEmoji)
        self.view.bringSubviewToFront(characterCount)
        super.viewWillAppear(animated)
        self.cameraTextView.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.New, context: nil)
        cameraTextView.becomeFirstResponder()
        shouldEdit = true
        
        videoClips = [] // Attempts to solve a bug associated with video clips crashing the app after redo is pressed. 
        arrayofText = [] // Clears array of text on view will appear. Attempts to solve the issue with unexpexted text in preview. 

    }

    func dismissTipView() {
        tipView.dismiss()
        
        if NSUserDefaults.standardUserDefaults().valueForKey("tip-5") == nil && NSUserDefaults.standardUserDefaults().valueForKey("tip-4") != nil {
            var preferences = EasyTipView.Preferences()
            preferences.drawing.font = UIFont(name: "AvenirNext-Medium", size: 14)!
            preferences.drawing.foregroundColor = UIColor.blackColor()
            preferences.drawing.backgroundColor = UIColor.whiteColor()
            preferences.drawing.arrowPosition = EasyTipView.ArrowPosition.Top
            preferences.animating.dismissDuration = 0.5
            tipView = EasyTipView(text: "Then tap RECORD and make an expression", preferences: preferences, delegate: self)
            tipView.show(animated: true, forView: headerView, withinSuperview: self.view)
            self.performSelector(#selector(cameraView.dismissTipView), withObject: nil, afterDelay: 4)
            NSUserDefaults.standardUserDefaults().setValue(true, forKey: "tip-5")
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

    override func viewDidAppear(animated: Bool) {
        videoCamera?.resumeCameraCapture()
        self.cameraTextView.performSelector(#selector(UIResponder.becomeFirstResponder), withObject: nil, afterDelay: 0)
    }
    override func viewWillDisappear(animated: Bool) {
            // print("disappear")

            shouldEdit = false
            self.cameraTextView.removeObserver(self, forKeyPath: "contentSize")
            actualOffset = self.scrollView.contentOffset
            cameraTextView.resignFirstResponder()
            newOne = true
            self.view.endEditing(true)
            
     }
    
    //status bar functions
    override func prefersStatusBarHidden() -> Bool {
            if showStatusBar {
                return false
            }
            return true
        }
    private func showStatusBar(enabled: Bool) {
            showStatusBar = enabled
            self.setNeedsStatusBarAppearanceUpdate()
        }
    
    
    
    
    
    //UITextView delegate functions
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        print("getting text...")

        
        
        if (self.cameraTextView.text == "What's on your mind? ") {
            self.cameraTextView.text = "".uppercaseString
            self.cameraTextView.textColor = UIColor.whiteColor()
            
        }
        
        else if (self.cameraTextView.text == "Anything else? ") {
            self.cameraTextView.text = "".uppercaseString
            self.cameraTextView.textColor = UIColor.whiteColor()
        }
        else {
            
        }
        
        
//        if tipView != nil {
//            dismissTipView()
//        }

        let  char = text.cStringUsingEncoding(NSUTF8StringEncoding)!
        let isBackSpace = strcmp(char, "\\b")

        if (textView.text != ""){
            shouldGoDown = true
        }
        if (isBackSpace == -92) {
            print("backspace was pressed")
            
            
            if (textView.text.characters.count == 1){
                print("current line has been cleared")
                self.recordButton.hidden = true
                self.recordEmoji.hidden = true
                self.characterCount.hidden = true

            }
            else if (textView.text == ""){
                
                print("editing the previous line")
                self.recordButton.hidden = true
                self.recordEmoji.hidden = true
                self.characterCount.hidden = true

                if (scrollView.subviews.count > 0) {

                    if (scrollView.subviews[scrollView.subviews.count-1] is UILabel){
                        print("button brought back")
                        print("SOUND EFFECT HERE")
                        

                        //animations
                        let buttonSpring = POPSpringAnimation(propertyNamed: kPOPViewScaleXY)
                        let buttonSpring2 = POPSpringAnimation(propertyNamed: kPOPViewScaleXY)
                        buttonSpring.toValue = NSValue(CGPoint: CGPointMake(1, 1))
                        buttonSpring.velocity = NSValue(CGPoint: CGPointMake(6, 6))
                        buttonSpring.springBounciness = 20.0
                        buttonSpring2.toValue = NSValue(CGPoint: CGPointMake(1, 1))
                        buttonSpring2.velocity = NSValue(CGPoint: CGPointMake(6, 6))
                        buttonSpring2.springBounciness = 20.0


                        self.recordButton.hidden = false
                        self.recordEmoji.hidden = false
                        self.characterCount.hidden = false

                        if (clipCount > 0){
                            
//                            if (self.cameraTextView.text == "Anything Else?") {
//                                self.cameraTextView.text = ""
//                            }

                            if (self.cameraTextView.returnKeyType == UIReturnKeyType.Done){
                                print("return button visible")

                                dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                                    self.cameraTextView.resignFirstResponder()
                                    self.cameraTextView.returnKeyType = UIReturnKeyType.Default
                                    self.cameraTextView.becomeFirstResponder()

                                }
                            }

                        }
                        recordButton.pop_addAnimation(buttonSpring, forKey: "spring")
                        recordEmoji.pop_addAnimation(buttonSpring2, forKey: "spring2")
                        characterCount.pop_addAnimation(buttonSpring2, forKey: "spring2")
                        let newLabel = scrollView.subviews[scrollView.subviews.count-1] as! UILabel
                        cameraTextView.text = newLabel.text
                        --scrollCounter
                        clipCount -= 1

                        do {
                            if arrayofText.count > 0 {
                                try fileManager?.removeItemAtPath("\(NSTemporaryDirectory())\(clipCount).mov")
                                
                                if arrayOfClipDurations.count > 0 {
                                    arrayOfClipDurations.removeLast()
                                }
                                
                                if arrayofText.count > 0 {
                                    arrayofText.removeLast()
                                }
                                
                                if videoClips != nil && videoClips.count > 0 {
                                    videoClips.removeLast()
                                }
                            }
                            
                        }
                        catch {}
                        
                        scrollHeight = scrollHeight - newLabel.bounds.size.height
                        self.scrollView.contentOffset = CGPoint(x: 0, y: self.scrollView.contentOffset.y-(self.cameraTextView.font?.lineHeight)!)
                        scrollView.subviews[scrollView.subviews.count-1].removeFromSuperview()
                    }
                }
                return false

            }

        }
        if (text == "Anything else? " && cameraTextView.returnKeyType != UIReturnKeyType.Done){
            return false
        }
        if (textView.text.characters.count == 0 && text != ""){
            print("1st character on new line")
            print("SOUND EFFECT HERE")


            if (text == "\n" && cameraTextView.returnKeyType == UIReturnKeyType.Done){
                print("send button pressed")


                mixPanel.track("done pressed", properties: nil)
                mixPanel.people .increment("done pressed", by: 1)
                mixPanel.identify(mixPanel.distinctId)
                mixPanel.flush()

                NSUserDefaults.standardUserDefaults().setObject(true, forKey: "shownAllTips")
                mergeAndExportVideo()

            

                self.view.bringSubviewToFront(recordButton)
                self.cameraTextView.resignFirstResponder()
                self.headerView.backgroundColor = UIColor .clearColor()
                self.view.endEditing(true)
                dispatch_async(dispatch_get_main_queue()) {
                    self.performSegueWithIdentifier("goPlayer", sender: self)
                }
                recordEmoji.hidden = true
                characterCount.hidden = true
                return false
            }
            else if (text == "\n" && cameraTextView.returnKeyType != UIReturnKeyType.Done){

                return false
            }


            let buttonSpring = POPSpringAnimation(propertyNamed: kPOPViewScaleXY)
            let buttonSpring2 = POPSpringAnimation(propertyNamed: kPOPViewScaleXY)
            buttonSpring.toValue = NSValue(CGPoint: CGPointMake(1, 1))
            buttonSpring.velocity = NSValue(CGPoint: CGPointMake(6, 6))
            buttonSpring.springBounciness = 20.0
            buttonSpring2.toValue = NSValue(CGPoint: CGPointMake(1, 1))
            buttonSpring2.velocity = NSValue(CGPoint: CGPointMake(6, 6))
            buttonSpring2.springBounciness = 20.0
            self.recordButton.hidden = false
            self.recordEmoji.hidden = false
            self.characterCount.hidden = false
            self.view.bringSubviewToFront(recordButton)
            self.view.bringSubviewToFront(recordEmoji)
            self.view.bringSubviewToFront(characterCount)
            recordButton.pop_addAnimation(buttonSpring, forKey: "spring")
            recordEmoji.pop_addAnimation(buttonSpring2, forKey: "spring2")
            characterCount.pop_addAnimation(buttonSpring2, forKey: "spring2")
            return true


        }

        if(cameraTextView.text.characters.count - range.length + text.characters.count > 70){
            return false;
        }
        return true
    }
    func textViewDidChange(textView: UITextView) {
        
        if cameraTextView.text.characters.count > 15 {
            if NSUserDefaults.standardUserDefaults().valueForKey("tip-4") == nil {
                var preferences = EasyTipView.Preferences()
                preferences.drawing.font = UIFont(name: "AvenirNext-Medium", size: 14)!
                preferences.drawing.foregroundColor = UIColor.blackColor()
                preferences.drawing.backgroundColor = UIColor.whiteColor()
                preferences.drawing.arrowPosition = EasyTipView.ArrowPosition.Top
                preferences.animating.dismissDuration = 0.5
                tipView = EasyTipView(text: "When finished look HERE", preferences: preferences, delegate: self)
                tipView.show(animated: true, forView: headerView, withinSuperview: self.view)
                NSUserDefaults.standardUserDefaults().setValue(true, forKey: "tip-4")
                self.performSelector(#selector(cameraView.dismissTipView), withObject: nil, afterDelay: 6)
            }
        }
        
        
        self.characterCount.text = String(70-self.cameraTextView.text.characters.count)
        let textHeight = self.cameraTextView.font?.lineHeight
        let pos = self.cameraTextView.endOfDocument
        let currentRect = self.cameraTextView.caretRectForPosition(pos)
        if (currentRect.origin.y > previousRect.origin.y){
            self.scrollView.contentOffset = CGPoint(x: 0, y: self.scrollView.contentOffset.y + textHeight!)

        }
        else if (currentRect.origin.y < previousRect.origin.y){
            if (shouldGoDown == true){

                self.scrollView.contentOffset = CGPoint(x: 0, y: self.scrollView.contentOffset.y - textHeight!)

            }


        }

        previousRect = currentRect;
        if (self.cameraTextView.text.characters.count == 0 && clipCount > 1){

            if (self.cameraTextView.returnKeyType == UIReturnKeyType.Default){

                dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                    self.cameraTextView.resignFirstResponder()
                    self.cameraTextView.returnKeyType = UIReturnKeyType.Done
                    self.cameraTextView.becomeFirstResponder()
                }
            }
        }
        else{
            print ("need to change send button")
            if (self.cameraTextView.returnKeyType == UIReturnKeyType.Done){
                dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                    self.cameraTextView.resignFirstResponder()
                    self.cameraTextView.returnKeyType = UIReturnKeyType.Default
                    self.cameraTextView.becomeFirstResponder()

                }



            }


        }



    }

    //keyboard + constraints functions
    func keyboardWillShow(notification: NSNotification) {

        updateBottomLayoutConstraintWithNotification(notification)

    }
    func keyboardWillHide (notification: NSNotification) {
        updateBottomLayoutConstraintWithNotification(notification)

    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        let textView = object as! UITextView
        var topCorrect = (textView.bounds.size.height - textView.contentSize.height)
        topCorrect = topCorrect < 0.0 ? 0.0 : topCorrect;
        textView.contentInset.top = topCorrect

    }
    func updateBottomLayoutConstraintWithNotification(notification: NSNotification) {


        let userInfo = notification.userInfo!
        let keyboardEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        let convertedKeyboardEndFrame = view.convertRect(keyboardEndFrame, fromView: view.window)
        recordButtonBottom.constant = CGRectGetMaxY(   view.bounds) - CGRectGetMinY(convertedKeyboardEndFrame) + 10

        if (self.cameraTextView.returnKeyType == UIReturnKeyType.Default){
            if (CGRectGetMaxY(view.bounds) != CGRectGetMinY(convertedKeyboardEndFrame)){
                dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                    //print ("uh oh")
                    self.scrollViewBottom.constant  = CGRectGetMaxY(self.view.bounds) - CGRectGetMinY(convertedKeyboardEndFrame) +
                    self.recordButton.bounds.height + 11 + 10 + 50
                    self.cameraTextViewBottom.constant = CGRectGetMaxY(self.view.bounds) - CGRectGetMinY(convertedKeyboardEndFrame) + self.recordButton.bounds.height + 10 + 11

                }
            }
            
            
        }
        
    }

    //camera functions
    func startRecording() {
        print ("starting recording...")
        print("SOUND EFFECT HERE")
        
        playSoundWithPath(NSBundle.mainBundle().pathForResource("beep_piano_hi_on", ofType: "aif")!)
        audioPlayer.volume = 0.025


        recording = true;
        let clipCountString = String(clipCount)
        movieWriter = GPUImageMovieWriter(movieURL: NSURL.fileURLWithPath("\(NSTemporaryDirectory())\(clipCountString).mov",isDirectory: true), size: CGSizeMake(self.view.bounds.size.width, self.view.bounds.size.height))
        filter?.addTarget(movieWriter)
        movieWriter?.encodingLiveVideo = true
        movieWriter?.hasAudioTrack = false
        self.videoCamera?.frameRate = 30
        movieWriter?.startRecording()


    }
    
    func stopRecording() {
        newImage?.removeFromSuperview()

        print ("stopping recording...")
        print("SOUND EFFECT HERE")
        
                if clipCount > 0 {
                    self.cameraTextView.text = "Anything else? "
                    self.cameraTextView.textColor = UIColor .blackColor().colorWithAlphaComponent(0.3)
                }

        
        playSoundWithPath(NSBundle.mainBundle().pathForResource("beep_piano_hi_off", ofType: "aif")!)
        audioPlayer.volume = 0.02
        
        if NSUserDefaults.standardUserDefaults().valueForKey("tip-6") == nil {
        
        var preferences = EasyTipView.Preferences()
        preferences.drawing.font = UIFont(name: "AvenirNext-Medium", size: 14)!
        preferences.drawing.foregroundColor = UIColor.blackColor()
        preferences.drawing.backgroundColor = UIColor.whiteColor()
        preferences.drawing.arrowPosition = EasyTipView.ArrowPosition.Top
        preferences.animating.dismissDuration = 0.5
        tipView = EasyTipView(text: "Write a few more thoughts, then tap DONE", preferences: preferences, delegate: self)
        tipView.show(animated: true, forView: headerView, withinSuperview: self.view)
        self.performSelector(#selector(cameraView.dismissTipView), withObject: nil, afterDelay: 10)
        NSUserDefaults.standardUserDefaults().setValue(true, forKey: "tip-6")
        }
        
        clipCount += 1
        recording = false;
        showStatusBar(true)
        self.headerView.hidden = false
        self.longPressRecognizer.enabled = true
        movieWriter?.finishRecording()
        
        if videoClips == nil {
            videoClips = []
            videoClips.append(NSURL.fileURLWithPath("\(NSTemporaryDirectory())\(clipCount - 1).mov", isDirectory: true))
        } else {
            videoClips.append(NSURL.fileURLWithPath("\(NSTemporaryDirectory())\(clipCount - 1).mov", isDirectory: true))
        }
        
        if clipCount == 1 {
            let view = UIView(frame: CGRectMake(0, 0, 1, 1))
            view.center = CGPointMake(self.view.center.x, self.view.center.y + 65)
            self.view.addSubview(view)
        }

    }
    
    func mergeAndExportVideo() {
        let composition = AVMutableComposition()
        let videoTrack = composition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        var time:Double = 0.0
        for video in videoClips {
            let asset = AVAsset(URL: video)
            let videoAssetTrack = asset.tracksWithMediaType(AVMediaTypeVideo)[0]
            let atTime = CMTime(seconds: time, preferredTimescale:1)
            do{
                try videoTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, asset.duration) , ofTrack: videoAssetTrack, atTime: atTime)
                arrayOfClipDurations.append(asset.duration.seconds)
            }catch{
                
            }
            time +=  asset.duration.seconds
            
        }
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .LongStyle
        dateFormatter.timeStyle = .ShortStyle
        let url = NSURL(fileURLWithPath: "\(NSTemporaryDirectory())edited_video.mov")
        
        let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
        exporter?.outputURL = url
        exporter?.shouldOptimizeForNetworkUse = false
        exporter?.outputFileType = AVFileTypeQuickTimeMovie
        exporter?.exportAsynchronouslyWithCompletionHandler({ () -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.exportCurrentVideo()
            })
            
        })
        
        
    }
    
    func exportCurrentVideo() {
        var shutterLayers = [ShutterLayer]()

        for i in 0..<arrayofText.count  {
            if arrayOfClipDurations.count == 1 {
                shutterLayers.append(ShutterLayer(previousClipDuration: 0, clipDuration:arrayOfClipDurations[i], title: arrayofText[i], line: i, bounds: self.view.bounds))
            } else if arrayOfClipDurations.count > 1 {
                var preferredDelay: Double = 0
                for var k in 0..<i {
                    preferredDelay += arrayOfClipDurations[k]
                }
                
                shutterLayers.append(ShutterLayer(previousClipDuration: preferredDelay, clipDuration:arrayOfClipDurations[i], title: arrayofText[i], line: i, bounds: self.view.bounds))
            }
        }
        
        let movieURL = "\(NSTemporaryDirectory())edited_video.mov"
        let shutter = Shutter(path: movieURL, layers: shutterLayers)
        shutter.export("\(NSTemporaryDirectory())edited_video.mov", callback: {
            
            var sum: Double = 0
            for (_, e) in self.arrayOfClipDurations.enumerate() {
                sum += e
            }
                        
            TrimVideo.sharedInstance.trimVideo(NSURL(fileURLWithPath: "\(NSTemporaryDirectory())edited_video.mov"), startTime: 0, endTime: Float(sum) - (Float(0.5) * Float(self.arrayOfClipDurations.count)))
        })
    }

    // edit view
    func longPressed(sender: UILongPressGestureRecognizer)

    {


        if (sender.state == UIGestureRecognizerState.Began){
            print("edit view loaded")
            print("SOUND EFFECT HERE")
            
            playSoundWithPath(NSBundle.mainBundle().pathForResource("digi_slide", ofType: "aif")!)
            audioPlayer.volume = 0.05


            print("Mixpanel event here")
            
            mixPanel.track("long-pressed", properties: nil)
            mixPanel.people .increment("long-pressed", by: 1)
            mixPanel.identify(mixPanel.distinctId)
            mixPanel.flush()

            self.headerView.backgroundColor = UIColor(red: 255/255, green: 110/255, blue: 110/255, alpha: 1.0)

            self.recordButton.userInteractionEnabled = false
            sender.enabled = false

            let blurEffect = UIBlurEffect(style: .Dark)
            let blurOverlay = UIVisualEffectView()

            let vibrancyEffect = UIVibrancyEffect(forBlurEffect: blurEffect)
            let vibrantOverlay = UIVisualEffectView(effect: vibrancyEffect)
            let overlayScrollView = UIScrollView(frame: CGRectMake(20,40+self.headerView.bounds.size.height,self.view.bounds.size.width-20,2*self.view.bounds.height/3))
            print (overlayScrollView.frame)
            overlayScrollView.showsVerticalScrollIndicator = true
            overlayScrollView.indicatorStyle = UIScrollViewIndicatorStyle.White
            overlayScrollView.userInteractionEnabled = true
            overlayScrollView.scrollEnabled = true
            overlayScrollView.delegate = self

            blurOverlay.frame = self.view.bounds
            vibrantOverlay.frame = self.view.bounds
            self.view.addSubview(blurOverlay)

            var scrollHeightOverlay:CGFloat = 0.0


            vibrantOverlay.contentView.addSubview(overlayScrollView)
            blurOverlay.contentView.addSubview(vibrantOverlay)



            for subview in scrollView.subviews{
                if subview is UILabel{


                    let olderLabel = subview as! UILabel
                    let newerLabel = UILabel(frame: CGRectMake(6, scrollHeightOverlay, self.view.bounds.size.width*(2/3)-20, 25))


                    newerLabel.font =  self.cameraTextView.font
                    newerLabel.textColor = UIColor.whiteColor()
                    newerLabel.text = olderLabel.text
                    newerLabel.numberOfLines = 0
                    newerLabel.sizeToFit()
                    overlayScrollView.addSubview(newerLabel)

                    // colored left-side border on edit view
                    let border = CALayer()
                    border.frame = CGRectMake(0 , scrollHeightOverlay+45+self.headerView.bounds.size.height, 2, CGRectGetHeight(newerLabel.frame)-12)
                    border.cornerRadius = 0.5
                    border.backgroundColor =  UIColor(red: 255/255, green: 110/255, blue: 110/255, alpha: 1.0).CGColor
                    vibrantOverlay.layer.addSublayer(border)
                    scrollHeightOverlay = scrollHeightOverlay + newerLabel.bounds.size.height + 10


                }

            }


            overlayScrollView.contentSize = CGSizeMake(self.view.bounds.size.width-20,scrollHeightOverlay)
            let timeStampLabel = UILabel(frame: CGRectMake(6, overlayScrollView.contentSize.height , self.view.bounds.size.width*(2/3)-20,25))
            timeStampLabel.font = UIFont(name:"RionaSans-Bold", size: 10.0)
            timeStampLabel.textColor = UIColor.whiteColor()
            timeStampLabel.text = ":: draft ::"
            timeStampLabel.numberOfLines = 0
            timeStampLabel.sizeToFit()
            overlayScrollView.addSubview(timeStampLabel)
            let emojiLabel = UILabel(frame: CGRectMake(6, overlayScrollView.contentSize.height+16, self.view.bounds.size.width*(2/3)-20,25))
            emojiLabel.font = UIFont(name:"Avenir Next", size:14)
            emojiLabel.textColor = UIColor.whiteColor()
            //emojiLabel.text = "✍🏻"
            emojiLabel.numberOfLines = 0
            timeStampLabel.sizeToFit()
            overlayScrollView.addSubview(emojiLabel)
            self.view.bringSubviewToFront(self.headerView)





            draftBottomSpacing.constant = -200
            
            overlayScrollView.transform = CGAffineTransformMakeTranslation (0, -1000)
            self.clearButton.hidden = false
            self.backButton.hidden = false
            self.clearEmoji.hidden = false
          
            cameraTextView.resignFirstResponder()
            UIView.animateWithDuration(0.1, animations: {


                blurOverlay.effect = blurEffect
                }, completion: {



                    finished in
                    if (finished){



                        overlayScrollView.flashScrollIndicators()
                        self.view.bringSubviewToFront(self.clearButton)
                        self.view.bringSubviewToFront(self.backButton)
                        self.view.bringSubviewToFront(self.headerView)
                        self.line.hidden = false
                        self.view.bringSubviewToFront(self.line)
                        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 3, options: .CurveEaseInOut, animations: {

                            self.backButton.transform = CGAffineTransformMakeTranslation(0, 0)
                            overlayScrollView.transform = CGAffineTransformMakeTranslation(0, 0)
                            self.view.layoutIfNeeded()
                        }) { _ in
                            let buttonSpring = POPSpringAnimation(propertyNamed: kPOPViewScaleXY)

                            buttonSpring.toValue = NSValue(CGPoint: CGPointMake(1, 1))
                            buttonSpring.velocity = NSValue(CGPoint: CGPointMake(6, 6))
                            buttonSpring.springBounciness = 20.0

                            self.clearEmoji.hidden = false
                            self.backEmoji.hidden = false
                            self.view.bringSubviewToFront(self.clearEmoji)
                            self.view.bringSubviewToFront(self.backEmoji)


                            //self.clearEmoji.pop_addAnimation(buttonSpring, forKey: "spring")
                        }
                        
                        self.draftBottomSpacing.constant = 17
                        UIView.animateWithDuration(0.5, delay: 0.1, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.7, options: .CurveEaseOut, animations: {
                            self.view.layoutIfNeeded()

                        }) { _ in
                            let buttonSpring = POPSpringAnimation(propertyNamed: kPOPViewScaleXY)

                            buttonSpring.toValue = NSValue(CGPoint: CGPointMake(1, 1))
                            buttonSpring.velocity = NSValue(CGPoint: CGPointMake(6, 6))
                            buttonSpring.springBounciness = 20.0
                            self.clearEmoji.hidden = false
                            self.view.bringSubviewToFront(self.clearEmoji)
                            //self.clearEmoji.pop_addAnimation(buttonSpring, forKey: "spring")

                        }
                    }
            })
        }

    }

    //text font and size for different phones

    func iPhoneScreenSizes(){
        let bounds = UIScreen.mainScreen().bounds
        let height = bounds.size.height

        switch height {
        case 480.0:
            // print("iPhone 3,4")
            self.cameraTextView.font = UIFont(name: "RionaSans-Black", size: 19)
        case 568.0:
            //print("iPhone 5")
            self.cameraTextView.font = UIFont(name: "RionaSans-Black", size: 20)
        case 667.0:
            //print("iPhone 6")
            self.cameraTextView.font = UIFont(name: "RionaSans-Black", size: 21)
        case 736.0:
            //print("iPhone 6+")
            self.cameraTextView.font = UIFont(name: "RionaSans-Black", size: 22 )
        default:
            break
            //print("not an iPhone")

        }


    }






    override func didReceiveMemoryWarning() {   
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func recordButtonPressed(sender: AnyObject) {
        print("record button pressed")
        print("Mixpanel event here")


        mixPanel.track("record button pressed", properties: nil)
        mixPanel.people .increment("record button pressed", by: 1)
        mixPanel.identify(mixPanel.distinctId)
        mixPanel.flush()



        if (cameraTextView.text.characters.count == 0){



            self.recordButton.userInteractionEnabled = false
            self.recordEmoji.userInteractionEnabled = false
            self.characterCount.userInteractionEnabled = false

            let buttonNo = POPSpringAnimation (propertyNamed: kPOPLayerPositionX)
            buttonNo.springBounciness = 20
            buttonNo.velocity = (1000)
            let buttonNo3 = POPSpringAnimation (propertyNamed: kPOPLayerPositionX)
            buttonNo3.springBounciness = 20
            buttonNo3.velocity = (1000)
            let buttonNo2 = POPSpringAnimation (propertyNamed: kPOPLayerPositionX)
            buttonNo2.springBounciness = 20
            buttonNo2.velocity = (1000)
            buttonNo.completionBlock = { (animation, finished) in
                if (finished){
                    self.recordButton.userInteractionEnabled = true
                }
            }
            buttonNo2.completionBlock = { (animation, finished) in
                if (finished){
                    self.recordEmoji.userInteractionEnabled = true
                    self.characterCount.userInteractionEnabled = true
                }
            }
            self.recordEmoji.pop_addAnimation(buttonNo2, forKey: "shake2")
            self.characterCount.pop_addAnimation(buttonNo3, forKey: "shake3")
            self.recordButton.pop_addAnimation(buttonNo, forKey: "shake")
           

        }
        else {
            
            self.recordButton.hidden = true
            self.recordEmoji.hidden = true
            self.characterCount.hidden = true

            self.showStatusBar(false)

            self.longPressRecognizer.enabled = false
            self.headerView.hidden = true
            self.newImage = GPUImageView()
            self.newImage?.fillMode = GPUImageFillModeType.PreserveAspectRatioAndFill
            self.newImage?.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)
            let newfilter = GPUImagePixellateFilter()
            self.videoCamera?.frameRate = 30
            self.videoCamera?.addTarget(newfilter)
            newfilter.addTarget(self.newImage)
            self.view.insertSubview(self.newImage!, aboveSubview:(self.filteredImage)!)
            self.recordButton.userInteractionEnabled = false
            self.cameraTextView.resignFirstResponder()
            let textHeight = self.cameraTextView.font?.lineHeight
            self.shouldGoDown = false
            if (self.oldLabel?.bounds.size.height != nil){
                self.scrollHeight = self.scrollHeight + (self.oldLabel?.bounds.size.height)!
            }
            
            
            self.filteredImage?.hidden = true


            let newLabel = UILabel(frame: CGRectMake(20, self.scrollView.bounds.size.height + self.scrollHeight, self.view.bounds.size.width*(2/3)-20, textHeight! ))
            newLabel.font = self.cameraTextView.font
            newLabel.textColor =  UIColor.whiteColor()

            ++self.scrollCounter
            newLabel.text = self.cameraTextView.text
            newLabel.numberOfLines = 0
            newLabel.sizeToFit()
            self.oldLabel = newLabel
            self.cameraTextView.text.removeAll()
            self.scrollView.addSubview(newLabel)
            newLabel.transform = CGAffineTransformMakeScale(1.5, 1.5)

            UIView.animateWithDuration(1, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 4.5, options: [], animations: { () -> Void in
                newLabel.transform = CGAffineTransformMakeScale(1, 1)
                }, completion: nil)


            UIView.animateWithDuration(0.5, animations: { () -> Void in
                self.scrollView.contentOffset = CGPoint(x: 0, y: self.scrollHeight+(self.oldLabel?.bounds.size.height)!   )
                }, completion: { (finished) -> Void in

                    UIView.animateWithDuration(2, animations: { () -> Void in
                        newLabel.alpha = 0.4
                    })
            })


            self.progressBarView.hidden = false
            self.animatedProgressBarView.hidden = false

            let time = (Int)(newLabel.bounds.size.height/(self.cameraTextView.font?.lineHeight)!)

            var duration:NSTimeInterval = 0
            switch (time){
            case 1:
                duration = 2

                break
            case 2:
                duration = 3
                break
            case 3:
                duration = 4
                break
            case 4:
                duration = 5
                break
            case 5:
                duration = 5
                break
            default:
                break
            }

            // record button visual state as its recording
            
            let moveUp = POPSpringAnimation(propertyNamed: kPOPLayerPositionY)
            let scaleDown = POPSpringAnimation(propertyNamed: kPOPViewSize)
            //scaleDown.toValue = NSValue(CGSize: CGSize(width: self.recordButton.bounds.size.width*0.2, height: self.recordButton.bounds.size.height*0.5))
            //moveUp.toValue = 27.5
            self.recordEmoji.hidden = true
            self.characterCount.hidden = true
            //self.recordButton.setTitle("look", forState: UIControlState.Normal)
            self.recordButton.layer.cornerRadius = 15
            //self.recordButton.titleLabel?.font = UIFont(name:"RionaSans-Black", size: 13.0)
            
            self.indicatorView = UIView(frame: CGRectMake(0, 0, 106, 30))
            self.indicatorView.center = CGPointMake(self.view.center.x, -30)
            self.indicatorView.layer.cornerRadius = 15
            self.indicatorView.clipsToBounds = true
            self.indicatorView.backgroundColor = UIColor.hex("#FF0000")
            self.view.addSubview(indicatorView)
            
            let indicatorLabel = UILabel(frame: CGRectMake(0, 0, 106, 30))
            indicatorLabel.textAlignment = NSTextAlignment.Center
            indicatorLabel.text = "LOOK HERE"
            indicatorLabel.font = UIFont(name:"RionaSans-Black", size: 12)
            indicatorLabel.textColor = .whiteColor()
            indicatorView.addSubview(indicatorLabel)
            
            self.startRecording()
            
            
            self.arrayofText.append(newLabel.text!)
            UIView.animateWithDuration(2, delay: 0, usingSpringWithDamping: 0.25, initialSpringVelocity: 0.25, options: [], animations: { () -> Void in
                self.indicatorView.center = CGPointMake(self.view.center.x, 30)
                }, completion: {(finished) -> Void in
            })
            
            self.view.bringSubviewToFront(self.recordButton)
            self.gradientView.hidden = false

            gradientView.frame = CGRectMake(0, 62, self.view.bounds.size.width, self.view.bounds.size.height - 124)
            gradientView.backgroundColor = UIColor.clearColor()
            gradientView.colors = [UIColor.clearColor(), UIColor.blackColor()]
            gradientView.locations = [1, 0]
            gradientView.direction = .Vertical
            gradientView.alpha = 0.25







            self.view.bringSubviewToFront(self.progressBarView)
            moveUp.completionBlock = { (animation, finished) in

                
                UIView.animateWithDuration(duration, delay: 0, options: [], animations: { () -> Void in
                    self.animatedProgressBarView.transform = CGAffineTransformMakeScale(0.0001, 1)
                    }, completion: { (finished) -> Void in
                        if (finished){
                            
                            self.filteredImage?.hidden = false
    
                            self.playSoundWithPath(NSBundle.mainBundle().pathForResource("etc_woosh_short", ofType: "aif")!)
                            self.audioPlayer.volume = 0.05
                            UIView.animateWithDuration(1, delay: 0, usingSpringWithDamping: 0.25, initialSpringVelocity: 0.5, options: [], animations: { () -> Void in
                                self.indicatorView.center = CGPointMake(self.view.center.x, -30)
                                }, completion: {(finished) -> Void in
                                    self.indicatorView.removeFromSuperview()

                            })
                            
                            UIView.animateWithDuration(1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.5, options: [], animations: { () -> Void in
                                self.recordButton.transform = CGAffineTransformMakeScale(0.0001, 0.0001)
                                self.characterCount.transform = CGAffineTransformMakeScale(0.0001, 0.0001)
                                self.recordEmoji.transform = CGAffineTransformMakeScale(0.0001, 0.0001)
                                }, completion: {(finished) -> Void in
                                    
                                    // record buttton visual state after recording
                                    //self.recordButton.titleLabel?.font = UIFont(name:"RionaSans-Bold", size: 15.0)
                                    self.recordButton.layer.cornerRadius = 6
                                    self.animatedProgressBarView.hidden = true
                                    self.animatedProgressBarView.transform = CGAffineTransformMakeScale(1, 1)
                                    self.progressBarView.hidden = true
                                    
                                    self.stopRecording()


                                    self.gradientView.hidden = false
                                    self.characterCount.text = "70"
                                    self.recordEmoji.hidden = false
                                    self.characterCount.hidden = false
                                    self.view.bringSubviewToFront(self.recordEmoji)
                                    self.view.bringSubviewToFront(self.characterCount)
                                    //self.recordButton.setTitle("record", forState: UIControlState.Normal)
                                    self.cameraTextView.returnKeyType = UIReturnKeyType.Done
                                    self.recordButton.hidden = true
                                    self.recordEmoji.hidden = true
                                    self.characterCount.hidden = true
                                    self.cameraTextView.becomeFirstResponder()
                                    self.recordButton.userInteractionEnabled = true
                                    self.recordButton.layer.borderWidth = 0
                                    UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.9, options: [], animations: { () -> Void in
                                        self.recordButton.transform = CGAffineTransformMakeScale(1, 1)
                                        self.characterCount.transform = CGAffineTransformMakeScale(1, 1)
                                        self.recordEmoji.transform = CGAffineTransformMakeScale(1, 1)
                                        }, completion: nil)
                                    
                            })
                        }
                        
                        
                })
            }
            self.recordButton.pop_addAnimation(moveUp, forKey: "moveUP")
            self.recordButton.pop_addAnimation(scaleDown, forKey: "scaleDown")
            
            
            
            
            
            

        }

        func willOutputSampleBuffer(sampleBuffer: CMSampleBuffer!) {
        }

    }

      //MARK: This takes you back to typing screen BUT clears typed text

    @IBAction func clearButtonPressed(sender: AnyObject) {
        print("text cleared")
        print("SOUND EFFECT HERE")


        playSoundWithPath(NSBundle.mainBundle().pathForResource("digi_powerdown", ofType: "aif")!)
        audioPlayer.volume = 0.25

        print("Mixpanel event here")
        
        mixPanel.track("clear button pressed", properties: nil)
        mixPanel.people .increment("clear button pressed", by: 1)
        mixPanel.identify(mixPanel.distinctId)
        mixPanel.flush()
        
        self.cameraTextView.textColor = UIColor .blackColor().colorWithAlphaComponent(0.3)
        self.cameraTextView.text = "What's on your mind? "
        self.cameraTextView.autocapitalizationType = UITextAutocapitalizationType.Sentences

               self.headerView.backgroundColor = UIColor .clearColor()
        self.backButton.hidden = true
        self.backEmoji.hidden = true
        self.clearButton.hidden = true
        self.clearEmoji.hidden = true
        self.headerView.hidden = true
        self.line.hidden = true

        self.recordButton.userInteractionEnabled = true
        longPressRecognizer.enabled = true
        self.scrollView.contentOffset = CGPoint(x: 0, y: 0)
        self.scrollHeight = 0
        for subview in self.scrollView.subviews {

            if subview is UILabel{
                subview.removeFromSuperview()
            }
        }
        clipCount = 1
        scrollCounter = 0
        do{
            let files = try fileManager?.contentsOfDirectoryAtPath(NSTemporaryDirectory())
            for file:NSString in files!{
                try fileManager?.removeItemAtPath("\(NSTemporaryDirectory())\(file)")
            }


        }
        catch {

        }

        self.cameraTextView.returnKeyType = UIReturnKeyType.Default


        arrayofText.removeAll()

        draftBottomSpacing.constant = -200
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.view.layoutIfNeeded()
        }) { (finished) -> Void in

            self.headerView.hidden = false
            self.clearEmoji.hidden = true
            self.backEmoji.hidden = true
            self.backButton.hidden = true
            self.clearButton.hidden = true

            for subview in self.view.subviews {
                if subview is UIVisualEffectView {
                    subview.removeFromSuperview()
                }
            }

            self.cameraTextView.becomeFirstResponder()
        }

    }




    //MARK: This takes you back to typing screen & keeps your typed text

    @IBAction func backButtonPressed(sender: AnyObject) {
        print("decided not to clear")
        print("SOUND EFFECT HERE")
        
        playSoundWithPath(NSBundle.mainBundle().pathForResource("click_03", ofType: "aif")!)
        audioPlayer.volume = 0.05


        print("Mixpanel event here")
        
        mixPanel.track("just reading pressed", properties: nil)
        mixPanel.people .increment("just reading button pressed", by: 1)
        mixPanel.identify(mixPanel.distinctId)
        mixPanel.flush()
        
        self.recordButton.userInteractionEnabled = true
        longPressRecognizer.enabled = true
        self.clearEmoji.hidden = true
        self.backEmoji.hidden = true
        self.headerView.hidden = true
        self.line.hidden = true
        
        draftBottomSpacing.constant = -200
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.headerView.backgroundColor = UIColor .clearColor()
            self.view.layoutIfNeeded()
        }) { (finished) -> Void in
            self.headerView.hidden = false
           // self.headerView.text = "caketalk"
           // self.headerView.font = UIFont (name: "RionaSans-Bold", size: 17)
            self.clearEmoji.hidden = true
            self.backEmoji.hidden = true
            self.backButton.hidden = true
            self.clearEmoji.hidden = true

            }
            for subview in self.view.subviews {
                if subview is UIVisualEffectView {
                    subview.removeFromSuperview()

                }
            }

            self.cameraTextView.becomeFirstResponder()
        }
    
    func updateBackgroundColorTransition() {
        filter!.useNextFrameForImageCapture()
        currentImage = filter!.imageFromCurrentFramebuffer()
        UIView.animateWithDuration(colorSamplingRate, animations: {
            if let currentImage = self.currentImage {
                self.coloredBackgroundView.backgroundColor = currentImage.areaAverage()
            }
            }, completion: { value in
        })
    }
    
    // MARK: EasyTipViewDelegate
    func easyTipViewDidDismiss(tipView : EasyTipView) {
    
    }
    
    // MARK: Prepare for Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.destinationViewController.classForCoder == playerView.classForCoder() {
            let vc = segue.destinationViewController as! playerView
            vc.arrayofText = self.arrayofText
            vc.firstFrameToPassImage = firstFrameToPassImage
            videoCamera?.pauseCameraCapture()
        }
    }
    
}



//MARK: This extension sets the line height of recorded labels

extension CALayer {

    func addBorder(edge: UIRectEdge, color: UIColor, thickness: CGFloat) {

        let border = CALayer()

        switch edge {
        case UIRectEdge.Top:
            border.frame = CGRectMake(0, 0, CGRectGetHeight(self.frame), thickness)
            break
        case UIRectEdge.Bottom:
            border.frame = CGRectMake(0, CGRectGetHeight(self.frame) - thickness, UIScreen.mainScreen().bounds.width, thickness)
            break
        case UIRectEdge.Left:
            border.frame = CGRectMake(-25 , 0, thickness, CGRectGetHeight(self.frame))
            break
        case UIRectEdge.Right:
            border.frame = CGRectMake(CGRectGetWidth(self.frame) - thickness, 0, thickness, CGRectGetHeight(self.frame))
            break
        default:
            break
        }

        border.backgroundColor = color.CGColor;

        self.addSublayer(border)
    }

}

extension UIImage {
    func areaAverage() -> UIColor {
        var bitmap = [UInt8](count: 4, repeatedValue: 0)
        
        // Create 1x1 context that interpolates pixels when drawing to it.
        let context = CGBitmapContextCreate(&bitmap, 1, 1, 8, 4, CGColorSpaceCreateDeviceRGB(), CGBitmapInfo.ByteOrderDefault.rawValue | CGImageAlphaInfo.PremultipliedLast.rawValue)!
        let inputImage = CGImage ?? CIContext().createCGImage(CIImage!, fromRect: CIImage!.extent)
        
        // Render to bitmap.
        CGContextDrawImage(context, CGRect(x: 0, y: 0, width: 1, height: 1), inputImage)
        
        // Compute result.
        let result = UIColor(red: CGFloat(bitmap[0]) / 255.0, green: CGFloat(bitmap[1]) / 255.0, blue: CGFloat(bitmap[2]) / 255.0, alpha: CGFloat(bitmap[3]) / 255.0)
        return result
    }
}
