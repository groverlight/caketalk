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
    
    let textLayer : CATextLayer! = CATextLayer()
    let blurbLayer: CALayer! = CALayer()
    let scrollLabel: UILabel! = UILabel()
    
    init(previousClipDuration: Double, clipDuration: Double, title: String, line : Int) {
        super.init()

        scrollLabel.frame = CGRectMake(20, 400, 400 - 20, 50)
        scrollLabel.textColor = UIColor.whiteColor()
        scrollLabel.font = UIFont(name:"RionaSans-Bold", size: preferredFontSize())
        scrollLabel.text = title
        scrollLabel.numberOfLines = 0
        scrollLabel.sizeToFit()
        scrollLabel.layer.cornerRadius = 10
        scrollLabel.layer.masksToBounds = true
        scrollLabel.setLineHeight(0)
        
        let overlayerLayer = CALayer()
        overlayerLayer.frame = self.bounds
        overlayerLayer.backgroundColor = UIColor.blackColor().CGColor
        overlayerLayer.opacity = 0.2
        overlayerLayer.masksToBounds = true
        self.addSublayer(overlayerLayer)
        
        blurbLayer.backgroundColor = randomColor(hue: .Random, luminosity: .Light).colorWithAlphaComponent(0.70).CGColor
        blurbLayer.cornerRadius = 10
        blurbLayer.frame = CGRectMake(-300, 150, scrollLabel.bounds.size.width + 20, scrollLabel.bounds.size.height + 15)
        self.addSublayer(blurbLayer)
        
        let textLayer = CATextLayer()
        textLayer.font = UIFont(name:"RionaSans-Bold", size: preferredFontSize())
        textLayer.fontSize = preferredFontSize()
        textLayer.string = title
        textLayer.foregroundColor = UIColor.whiteColor().CGColor
        textLayer.frame = CGRectMake(10, 0, blurbLayer.bounds.size.width - 10, blurbLayer.bounds.size.height - 10)
        textLayer.alignmentMode = kCAAlignmentLeft;
        textLayer.masksToBounds = true
        blurbLayer.addSublayer(textLayer)
        
        let comeInAnimation = CASpringAnimation(keyPath: "position.x")
        comeInAnimation.damping = 30
        comeInAnimation.initialVelocity = 0.5
        comeInAnimation.duration = 0.6
        comeInAnimation.beginTime = AVCoreAnimationBeginTimeAtZero + previousClipDuration
        comeInAnimation.fromValue = -300
        comeInAnimation.fillMode = kCAFillModeForwards;
        comeInAnimation.removedOnCompletion = false;
        comeInAnimation.toValue = (blurbLayer.bounds.size.width / 2) + 30
        blurbLayer.addAnimation(comeInAnimation, forKey: "comeInAnimation")

        let fadeOutAnimation = CABasicAnimation(keyPath: "opacity")
        fadeOutAnimation.fromValue = 1
        fadeOutAnimation.toValue = 0
        
        let goUpAnimation = CABasicAnimation(keyPath: "position.y")
        goUpAnimation.fromValue = 150
        goUpAnimation.toValue = 500
        goUpAnimation.autoreverses = false
        
        let animationGroup = CAAnimationGroup()
        animationGroup.fillMode = kCAFillModeForwards;
        animationGroup.removedOnCompletion = false;
        animationGroup.beginTime = AVCoreAnimationBeginTimeAtZero + previousClipDuration + 0.6
        animationGroup.duration = clipDuration + 4.25
        animationGroup.animations = [fadeOutAnimation, goUpAnimation]
        blurbLayer.addAnimation(animationGroup, forKey: "animationGroup")
    }

    
    func preferredFontSize() -> CGFloat {
        let bounds = UIScreen.mainScreen().bounds
        let height = bounds.size.height
        
        switch height {
        case 480.0:
            return 19
        case 568.0:
            return 20
        case 667.0:
            return 21
        case 736.0:
            return 22
        default:
            break
            
        }
        
        return 0
    }
    
    
    func resize(rect:CGSize){}
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}