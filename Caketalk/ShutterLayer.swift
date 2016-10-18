//
//  ShutterLayer.swift
//  Shutter
//
//  Created by Olivier Lesnicki on 20/06/2015.
//  Copyright (c) 2015 LEMOTIF. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore
import AVFoundation

class ShutterLayer : CALayer {
    
    let blurbTextView: UITextView! = UITextView()
    
    var labelFont: UIFont!

    init(previousClipDuration: Double, clipDuration: Double, title: String, line : Int, bounds: CGRect) {
        super.init()


        //-blurbLabel.bounds.size.width

        iPhoneScreenSizes()
        blurbTextView.frame = CGRectMake(100, bounds.size.height * 0.40, bounds.size.width * (2 / 3) + 20, 50)
        blurbTextView.textColor = UIColor.whiteColor()
        blurbTextView.font = labelFont
        blurbTextView.text = title
        blurbTextView.sizeToFit()
        blurbTextView.layer.cornerRadius = 10
        blurbTextView.layer.masksToBounds = true
        blurbTextView.alpha = 0
        blurbTextView.backgroundColor = randomColor(hue: .Random, luminosity: .Light).colorWithAlphaComponent(0.70)
        self.addSublayer(blurbTextView.layer)
        
        
        
        
        let comeInAnimation = CASpringAnimation(keyPath: "position.x")
        comeInAnimation.damping = 10
        comeInAnimation.initialVelocity = 1
        comeInAnimation.fromValue = 0
        comeInAnimation.toValue = (blurbTextView.bounds.size.width / 2) + 30
        
        let fadeInAnimation = CABasicAnimation(keyPath: "opacity")
        fadeInAnimation.fromValue = 0
        fadeInAnimation.toValue = 1
        
        let firstAnimationGroup = CAAnimationGroup()
        firstAnimationGroup.fillMode = kCAFillModeForwards;
        firstAnimationGroup.removedOnCompletion = false;
        firstAnimationGroup.duration = 2
        firstAnimationGroup.animations = [comeInAnimation, fadeInAnimation]
        firstAnimationGroup.beginTime = AVCoreAnimationBeginTimeAtZero + previousClipDuration
        blurbTextView.layer.addAnimation(firstAnimationGroup, forKey: "firstAnimationGroup")
        
        
        
        let fadeOutAnimation = CABasicAnimation(keyPath: "opacity")
        fadeOutAnimation.fromValue = 1
        fadeOutAnimation.toValue = 0
        
        let goUpAnimation = CABasicAnimation(keyPath: "position.y")
        goUpAnimation.fromValue = blurbTextView.center.y
        goUpAnimation.toValue = 500
        
        let animationGroup = CAAnimationGroup()
        animationGroup.fillMode = kCAFillModeForwards;
        animationGroup.removedOnCompletion = false;
        animationGroup.beginTime = AVCoreAnimationBeginTimeAtZero + previousClipDuration + 0.5
        animationGroup.duration = clipDuration + 4
        animationGroup.animations = [goUpAnimation, fadeOutAnimation]
        blurbTextView.layer.addAnimation(animationGroup, forKey: "animationGroup")
    }

    
    func iPhoneScreenSizes(){
        let bounds = UIScreen.mainScreen().bounds
        let height = bounds.size.height
        
        switch height {
        case 480.0:
            labelFont = UIFont(name: "RionaSans-Bold", size: 19)
        case 568.0:
            labelFont = UIFont(name: "RionaSans-Bold", size: 20)
        case 667.0:
            labelFont = UIFont(name: "RionaSans-Bold", size: 21)
        case 736.0:
            labelFont = UIFont(name: "RionaSans-Bold", size: 22 )
        default:
            break
        }
        
    }
    
    
    func resize(rect:CGSize){}
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}