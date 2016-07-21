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
    
    init(title: String, line : Int) {
        super.init()
        
        iPhoneScreenSizes()
        
        let overlayerLayer = CALayer()
        overlayerLayer.frame = self.bounds
        overlayerLayer.backgroundColor = UIColor.blackColor().CGColor
        overlayerLayer.opacity = 0.2
        overlayerLayer.masksToBounds = true
        self.addSublayer(overlayerLayer)
        
        let textLayer = CATextLayer()
        textLayer.font = UIFont.systemFontOfSize(26, weight: UIFontWeightSemibold)
        textLayer.string = title
        textLayer.foregroundColor = UIColor.whiteColor().CGColor
        textLayer.frame = CGRectMake(30, 500 - (CGFloat(line) * 70), 350, 50)
        textLayer.alignmentMode = kCAAlignmentLeft;
        self.addSublayer(textLayer)
        
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.duration = 1
        if line == 0 {
            animation.beginTime = AVCoreAnimationBeginTimeAtZero
        } else {
            animation.beginTime = Double(line) * 2
        }
        
        animation.fromValue = NSNumber(float: 0)
        animation.toValue = NSNumber(float: 1)
        animation.removedOnCompletion = false
        animation.fillMode = kCAFillModeBoth
        animation.additive = false
        textLayer.addAnimation(animation, forKey: "opacityIN")
        
        //        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        //        animation.beginTime = CMTimeGetSeconds(img.startTime);
        //        animation.duration = CMTimeGetSeconds(_timeline.transitionDuration);
        //        animation.fromValue = [NSNumber numberWithFloat:0.0f];
        //        animation.toValue = [NSNumber numberWithFloat:1.0f];
        //        animation.removedOnCompletion = NO;
        //        animation.fillMode = kCAFillModeBoth;
        //        animation.additive = NO;
        //        [parentLayer addAnimation:animation forKey:@"opacityIN"];
        
        
    }
    
    func iPhoneScreenSizes(){
                let bounds = UIScreen.mainScreen().bounds
                let height = bounds.size.height
        
                switch height {
                    case 480.0:
                            //print("iPhone 3,4")
                                textLayer.font = UIFont(name: "RionaSans-Bold", size: 19)
                    case 568.0:
                            //print("iPhone 5")
                                textLayer.font = UIFont(name: "RionaSans-Bold", size: 20)
                    case 667.0:
                            //print("iPhone 6")
                                textLayer.font = UIFont(name: "RionaSans-Bold", size: 21)
                    case 736.0:
                            //print("iPhone 6")
                                textLayer.font = UIFont(name: "RionaSans-Bold", size: 22 )
                    default:
                            break
                            //print("not an iPhone")
                                
                    }
    }
        
    
    func resize(rect:CGSize){}
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}