//
//  Shutter.swift
//  Shutter
//
//  Created by Olivier Lesnicki on 20/06/2015.
//  Copyright (c) 2015 LEMOTIF. All rights reserved.
//


import Foundation
import UIKit
import AVFoundation
import AssetsLibrary

class Shutter {
    
    var layers : [ShutterLayer]
    var path : String
    var watermarkImageView: UIImageView!
    
    init(path: String, layers: [ShutterLayer]) {
        self.layers = layers
        self.path = path
    }
    
    func export(exportPath: String, callback: () -> (Void)) {
        
        let videoUrl = NSURL(fileURLWithPath: path)
        let video = AVURLAsset(URL: videoUrl, options: nil)
        let videoTracks = video.tracksWithMediaType(AVMediaTypeVideo)
        let videoTrack : AVAssetTrack = videoTracks[0]
        
        let composition = AVMutableComposition()
        let compositionTrackForVideo = composition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: CMPersistentTrackID())
        
        do {
            try compositionTrackForVideo.insertTimeRange(
                CMTimeRangeMake(kCMTimeZero, video.duration),
                ofTrack: videoTrack ,
                atTime: kCMTimeZero)
        } catch _ {
        }
        
        compositionTrackForVideo.preferredTransform = videoTrack.preferredTransform
        
        let size = compositionTrackForVideo.naturalSize
        
        let parentLayer = CALayer()
        parentLayer.frame = CGRectMake(0, 0, size.width, size.height)
        
        let videoLayer = CALayer()
        videoLayer.frame = CGRectMake(0, 0, size.width, size.height)
        
        let overlayLayer = CALayer()
        overlayLayer.frame = CGRectMake(0, 0, size.width, size.height)
        
        for layer in layers {
            print("Add sublayer")
            layer.resize(size)
            overlayLayer.addSublayer(layer)
        }
        
        parentLayer.addSublayer(videoLayer)
        
        let gradientLayer = CALayer()
        overlayLayer.frame = CGRectMake(0, 0, size.width, size.height)
        gradientLayer.backgroundColor = UIColor.blackColor().CGColor
        parentLayer.addSublayer(gradientLayer)
        
        parentLayer.addSublayer(overlayLayer)
        
        watermarkImageView = UIImageView(frame: CGRectMake(size.width - 110, 10, 100, 40))
        //  watermarkImageView.image = UIImage(named: "")
        watermarkImageView.backgroundColor = .greenColor()
        parentLayer.addSublayer(watermarkImageView.layer)
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = size
        videoComposition.frameDuration = CMTimeMake(1, 30)
        
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
            postProcessingAsVideoLayer: videoLayer,
            inLayer: parentLayer
        )
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, composition.duration);
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        instruction.layerInstructions = [layerInstruction]
        
        videoComposition.instructions = [instruction]
        
        if (NSFileManager.defaultManager().fileExistsAtPath(exportPath)) {
            do {
                try NSFileManager.defaultManager().removeItemAtPath(exportPath)
            } catch _ {
            }
        }
        
        let exportURL = NSURL(fileURLWithPath: exportPath)
        
        let export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)!
        export.videoComposition = videoComposition
        export.outputURL = exportURL
        export.outputFileType = AVFileTypeQuickTimeMovie
        export.shouldOptimizeForNetworkUse = true
        
        print("Export")
        
        export.exportAsynchronouslyWithCompletionHandler({
            print("Export done")
            dispatch_async(dispatch_get_main_queue()) {
                callback()
            }
        })
        
    }
    
    
    
}
