import AVFoundation
import Foundation

public class TrimVideo {
    
    // MARK: Citation usage @ http://stackoverflow.com/questions/35696188/how-to-trim-a-video-in-swift-for-a-particular-time
    
    static let sharedInstance = TrimVideo()
    
    func trimVideo(sourceURL: NSURL, startTime:Float, endTime:Float) {
        let manager = NSFileManager.defaultManager()
        
        let asset = AVAsset(URL: sourceURL)
        let length = Float(asset.duration.value) / Float(asset.duration.timescale)
        
        print("The length \(length)")
        
        let start = startTime
        let end = endTime
        
        let exportPath = "\(NSTemporaryDirectory())edited_video.mov"
        let exportURL = NSURL(fileURLWithPath: "\(NSTemporaryDirectory())edited_video.mov")
        if (NSFileManager.defaultManager().fileExistsAtPath(exportPath)) {
            do {
                try NSFileManager.defaultManager().removeItemAtPath(exportPath)
            } catch _ {
            }
        }
        
        let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)!
        export.outputURL = exportURL
        export.outputFileType = AVFileTypeQuickTimeMovie
        export.shouldOptimizeForNetworkUse = true
        
        print("Export")
        
        export.exportAsynchronouslyWithCompletionHandler({
            completion in
            print("Completed trimming")
        })
    
    }
}
