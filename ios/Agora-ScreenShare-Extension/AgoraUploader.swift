//
//  AgoraUploader.swift
//  Agora-ScreenShare-Extension
//
//  Created by Eizar Paing on 5/26/21.
//

import Foundation
import CoreMedia
import ReplayKit
import AgoraRtcKit

class AgoraUploader {
    private static let videoDimension : CGSize = {
        let screenSize = UIScreen.main.currentMode!.size
        var boundingSize = CGSize(width: 540, height: 960)
        let mW = boundingSize.width / screenSize.width
        let mH = boundingSize.height / screenSize.height
        if( mH < mW ) {
            boundingSize.width = boundingSize.height / screenSize.height * screenSize.width
        }
        else if( mW < mH ) {
            boundingSize.height = boundingSize.width / screenSize.width * screenSize.height
        }
        return boundingSize
    }()
    
    private static let audioSampleRate: UInt = 48000
    private static let audioChannels: UInt = 2
    
    private static let sharedAgoraEngine: AgoraRtcEngineKit = {
        let kit = AgoraRtcEngineKit.sharedEngine(withAppId: KeyCenter.AppId, delegate: nil)
        kit.setChannelProfile(.liveBroadcasting)
        kit.setClientRole(.broadcaster)
        
        kit.enableVideo()
        kit.setExternalVideoSource(true, useTexture: true, pushMode: true)
        let videoConfig = AgoraVideoEncoderConfiguration(size: videoDimension,
                                                         frameRate: .fps24,
                                                         bitrate: AgoraVideoBitrateStandard,
                                                         orientationMode: .adaptative)
        kit.setVideoEncoderConfiguration(videoConfig)
        kit.setAudioProfile(.musicStandardStereo, scenario: .default)
        
        kit.enableExternalAudioSource(withSampleRate: audioSampleRate,
                                      channelsPerFrame: audioChannels)
        
        kit.muteAllRemoteVideoStreams(true)
        kit.muteAllRemoteAudioStreams(true)
        
        return kit
    }()
    
    static func startBroadcast(to channel: String) {
        let SCREEN_SHARE_UID_MIN:UInt = 501
        let SCREEN_SHARE_UID_MAX:UInt = 1000
        let SCREEN_SHARE_UID = UInt.random(in: SCREEN_SHARE_UID_MIN...SCREEN_SHARE_UID_MAX)
//        sharedAgoraEngine.joinChannel(byToken: KeyCenter.Token, channelId: "mychannel", info: nil, uid: SCREEN_SHARE_UID, joinSuccess: nil)
        let dataShared = UserDefaults(suiteName: "group.com.clsm.agora")
        if let token = dataShared?.object(forKey: "token") as? String {
            sharedAgoraEngine.joinChannel(byToken: token, channelId: "mychannel", info: nil, uid: 0, joinSuccess: nil)
        }
        var dataStreamID:Int = -1
        sharedAgoraEngine.createDataStream(&dataStreamID, reliable: true, ordered: true)
        sharedAgoraEngine.setEnableSpeakerphone(true)
    }
    
    static func sendVideoBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard let videoFrame = CMSampleBufferGetImageBuffer(sampleBuffer)
             else {
            return
        }
        
        var rotation : Int32 = 0
        if let orientationAttachment = CMGetAttachment(sampleBuffer, key: RPVideoSampleOrientationKey as CFString, attachmentModeOut: nil) as? NSNumber {
            if let orientation = CGImagePropertyOrientation(rawValue: orientationAttachment.uint32Value) {
                switch orientation {
                case .up,    .upMirrored:    rotation = 0
                case .down,  .downMirrored:  rotation = 180
                case .left,  .leftMirrored:  rotation = 90
                case .right, .rightMirrored: rotation = 270
                default:   break
                }
            }
        }
        
        //let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let time = CMTime(seconds: CACurrentMediaTime(), preferredTimescale: 1000)
        
        let frame = AgoraVideoFrame()
        frame.format = 12
        frame.time = time
        frame.textureBuf = videoFrame
        frame.rotation = rotation
        sharedAgoraEngine.pushExternalVideoFrame(frame)
    }
    
    static func sendAudioAppBuffer(_ sampleBuffer: CMSampleBuffer) {
        AgoraAudioTube.agoraKit(sharedAgoraEngine,
                                pushAudioCMSampleBuffer: sampleBuffer,
                                resampleRate: audioSampleRate,
                                type: .app)
    }
    
    static func sendAudioMicBuffer(_ sampleBuffer: CMSampleBuffer) {
        AgoraAudioTube.agoraKit(sharedAgoraEngine,
                                pushAudioCMSampleBuffer: sampleBuffer,
                                resampleRate: audioSampleRate,
                                type: .mic)
    }
    
    static func stopBroadcast() {
//        print("leaving")
        sharedAgoraEngine.leaveChannel(nil)
    }
}

