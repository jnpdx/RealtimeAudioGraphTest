//
//  AudioInputController.swift
//  RealtimeAudioGraphTest
//
//  Created by John Nastos on 1/7/21.
//

import Combine
import AVFoundation
import Accelerate
import os.log

class AudioInputController : ObservableObject {
    var audioBuffer = [Float](repeating: 0.0, count: 9000)
    private let dataSubject = CurrentValueSubject<Float, Never>(0.0)
    var dataPublisher : AnyPublisher<Float, Never> {
        dataSubject
            .eraseToAnyPublisher()
    }
    private var audioEngine = AVAudioEngine()
    
    func setupEngine() {
        setupAudioSession()
        audioEngine = AVAudioEngine()
        
        var processingBuffer = [Float](repeating: 0.0, count: 9000)
        var processingBuffer2 = [Float](repeating: 0.0, count: 9000)
        var high:Float = 1.0
        var low:Float = 0.0
        
        let recordingFormat = audioEngine.inputNode.inputFormat(forBus: 0)
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (pcmBuffer, timestamp) in
            
            let samplesPerPixel = 40
            let bufferLength = vDSP_Length(pcmBuffer.frameLength)
            
            vDSP_vabs(pcmBuffer.floatChannelData![0], 1, &processingBuffer, 1, bufferLength)
            vDSP_vclip(processingBuffer, 1, &low, &high, &processingBuffer, 1, bufferLength)
            
            let pixelCount = Int(pcmBuffer.frameLength) / samplesPerPixel
            let filter = [Float](repeating: 1.0/Float(samplesPerPixel), count: Int(samplesPerPixel))
            
            vDSP_desamp(processingBuffer,
                            vDSP_Stride(samplesPerPixel),
                            filter, &processingBuffer,
                            vDSP_Length(pixelCount),
                            vDSP_Length(samplesPerPixel))
            
            
            memcpy(&processingBuffer2, &self.audioBuffer, MemoryLayout<Float32>.size * processingBuffer2.count)

            //stick the processing buffer at the end of the audio buffer
//            for frameIndex in 0..<pixelCount {
//                self.audioBuffer[self.audioBuffer.count - pixelCount + frameIndex] = processingBuffer[frameIndex]
//            }
            memcpy(&self.audioBuffer[self.audioBuffer.count - pixelCount], &processingBuffer, MemoryLayout<Float32>.size * pixelCount)
            
            _ = processingBuffer2.withUnsafeBufferPointer { (rawBufferPointer) in
                memcpy(&self.audioBuffer, rawBufferPointer.baseAddress! + pixelCount, MemoryLayout<Float32>.size *  (processingBuffer2.count - pixelCount))
            }
            
            self.dataSubject.send(Float.random(in: 0.0...2.0))
        }
        audioEngine.prepare()
    }
    
    func setupAudioSession() {
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setActive(true)
            try session.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker])
        } catch {
            assertionFailure("Error setting session active: \(error.localizedDescription)")
        }
        #endif
    }
    
    func start() {
        do {
            try audioEngine.start()
        } catch {
            fatalError("Couldn't start engine")
        }
    }
}
