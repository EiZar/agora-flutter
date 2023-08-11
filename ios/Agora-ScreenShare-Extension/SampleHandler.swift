//
//  SampleHandler.swift
//  Agora-ScreenShare-Extension
//
//  Created by Eizar Paing on 5/25/21.
//

import ReplayKit

class SampleHandler: RPBroadcastSampleHandler {
    
    var bufferCopy: CMSampleBuffer?
    var lastSendTs: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    var timer: Timer?

    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        AgoraUploader.startBroadcast(to: "mychannel")
//
        DispatchQueue.main.async {
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) {[weak self] (timer:Timer) in
                guard let weakSelf = self else {return}
                let elapse = Int64(Date().timeIntervalSince1970 * 1000) - weakSelf.lastSendTs
//                print("elapse: \(elapse)")
                // If the inter-frame interval of the video is too long, resend the previous frame.
                if(elapse > 300) {
                    if let buffer = weakSelf.bufferCopy {
                        weakSelf.processSampleBuffer(buffer, with: .video)
                    }
                }
            }
        }
        // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
    }
    
    override func broadcastPaused() {
        // User has requested to pause the broadcast. Samples will stop being delivered.
    }
    
    override func broadcastResumed() {
        // User has requested to resume the broadcast. Samples delivery will resume.
    }
    
    override func broadcastFinished() {
        // User has requested to finish the broadcast.
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        DispatchQueue.main.async {[weak self] in
        switch sampleBufferType {
            case RPSampleBufferType.video:
                // Handle video sample buffer
                if let weakSelf = self {
                    weakSelf.bufferCopy = sampleBuffer
                    weakSelf.lastSendTs = Int64(Date().timeIntervalSince1970 * 1000)
                }
                AgoraUploader.sendVideoBuffer(sampleBuffer)
                break
            case RPSampleBufferType.audioApp:
                // Handle audio sample buffer for app audio
                AgoraUploader.sendAudioAppBuffer(sampleBuffer)
                break
            case RPSampleBufferType.audioMic:
                // Handle audio sample buffer for mic audio
                AgoraUploader.sendAudioMicBuffer(sampleBuffer)
                break
            @unknown default:
                // Handle other sample buffer types
                fatalError("Unknown type of sample buffer")
            }
        }
    }
}
