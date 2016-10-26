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
        
        do {
            try manager.removeItemAtURL(NSURL(fileURLWithPath: "\(NSTemporaryDirectory())edited_video.mov"))
        } catch {
            
        }
        
        var outputURL = NSURL(fileURLWithPath: "\(NSTemporaryDirectory())edited_video.mov")
        do {
            try manager.createDirectoryAtURL(outputURL, withIntermediateDirectories: true, attributes: nil)
            outputURL = NSURL(fileURLWithPath: "\(NSTemporaryDirectory())edited_video.mov")
        }catch let error {
            print(error)
        }
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {return}
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileTypeMPEG4
        
        let startTime = CMTime(seconds: Double(start ?? 0), preferredTimescale: 1000)
        let endTime = CMTime(seconds: Double(end ?? length), preferredTimescale: 1000)
        let timeRange = CMTimeRange(start: startTime, end: endTime)
        
        exportSession.timeRange = timeRange
    }
}
