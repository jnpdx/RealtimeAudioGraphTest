//
//  ContentView.swift
//  RealtimeAudioGraphTest
//
//  Created by John Nastos on 1/6/21.
//

import SwiftUI
import Combine
import AVFoundation
import os.log

class DataProvider : ObservableObject {
    var timer : Timer?
    
    var dataPublisher : AnyPublisher<[Float], Never> {
        return dataSubject
            .receive(on: RunLoop.main)
            .throttle(for: .milliseconds(Int(1.0 / 30.0 * 1000.0)), scheduler: RunLoop.main, latest: false)
            .eraseToAnyPublisher()
    }
    private let dataSubject = CurrentValueSubject<[Float], Never>([0.0])
    private var generate = false
    
    init() {
        
    }
    
    func startGenerating() {
        generate = true
        var floatData = [Float](repeating: 0, count: 1000)

        DispatchQueue.global(qos: .default).async {
            while self.generate {
                for index in 0..<floatData.count {
                    floatData[index] = Float.random(in: 0...1.0)
                }
                self.dataSubject.send(floatData)
                usleep(1_000_000 / 60)
            }
        }
    }
}

class AudioInputController : ObservableObject {
    var audioBuffer : ContiguousArray<Float> = ContiguousArray<Float>(repeating: 0.0, count: 8000)
    private let dataSubject = CurrentValueSubject<Float, Never>(0.0)
    var dataPublisher : AnyPublisher<Float, Never> {
        dataSubject
            .eraseToAnyPublisher()
    }
    var audioEngine = AVAudioEngine()
    
    func setupEngine() {
        setupAudioSession()
        audioEngine = AVAudioEngine()
        let recordingFormat = audioEngine.inputNode.inputFormat(forBus: 0)
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (pcmBuffer, timestamp) in
            //take the previous frames and shift them left

            let insertionIndex = (self.audioBuffer.count - Int(pcmBuffer.frameLength))
//
//            var bufferCopy = self.audioBuffer
//
//            memcpy(&self.audioBuffer[0], &bufferCopy[Int(pcmBuffer.frameLength)], insertionIndex * MemoryLayout<Float32>.size)
//
            //write the new stuff onto the end
            memcpy(&self.audioBuffer[insertionIndex], pcmBuffer.floatChannelData!.pointee, MemoryLayout<Float32>.size * Int(pcmBuffer.frameLength))
            //memset(&self.audioBuffer[0], 0, MemoryLayout<Float32>.size)
            //self.audioBuffer[0] = Float.random(in: 0.0...1.0)
            
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

struct ContentView: View {
    @ObservedObject var dataProvider = DataProvider()
    var audioInputController = AudioInputController()
    //@State var valuesToDisplay : ContiguousArray<Float> = []
    @State var timestamp : UInt64 = 0
    
    @State private var cancelables = Set<AnyCancellable>()
    
    var body: some View {
//        VStack {
//            Text("Hello, world!")
//            if valueToDisplay.count > 1 {
//                Text("\(valueToDisplay[0]),\(valueToDisplay[1])")
//            }
//        }
        AudioVisualization(timestamp: timestamp, audioInputController: audioInputController)
        .padding()
        .onReceive(dataProvider.dataPublisher) { newValue in
            //valuesToDisplay = newValue
        }
        .onAppear {
            //dataProvider.startGenerating()
            audioInputController.setupEngine()
            audioInputController.start()
            cancelables.insert(
                audioInputController
                    .dataPublisher
                    //.throttle(for: .milliseconds(Int(1.0 / 200.0 * 1000.0)), scheduler: RunLoop.main, latest: false)
                    .sink { _ in
                        self.timestamp = mach_absolute_time()
                        //self.valuesToDisplay = audioInputController.audioBuffer
                }
            )
        }
    }
}

let kSamplesPerPixel : UInt32 = 40

struct AudioVisualization: View {
    var timestamp : UInt64
    var audioInputController : AudioInputController
    
    var body: some View {
        GeometryReader { geometry in
            
            //draw a grid every 1000 samples
            Path { path in
                //os_log("Frame: %f",(Date().timeIntervalSince1970))
                let gridColumnWidth = CGFloat(1000) / CGFloat(kSamplesPerPixel)
                for gridColumnIndex in 0..<Int(geometry.size.width/gridColumnWidth) {
                    path.move(to: CGPoint(x: CGFloat(gridColumnIndex) * gridColumnWidth, y: 0))
                    path.addLine(to: CGPoint(x: CGFloat(gridColumnIndex) * gridColumnWidth, y: geometry.size.height))
                }
            }
            .stroke(Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 0.1))
            .drawingGroup()
            
            //the waveform
            Path { path in
                let pointWidth = geometry.size.width / CGFloat(audioInputController.audioBuffer.count)
                let halfHeight = geometry.size.height / 2
                for pointIndex in 0..<audioInputController.audioBuffer.count {//min(5,graphData.count) {
                    let pointValue = audioInputController.audioBuffer[pointIndex]
                    let xPos = CGFloat(pointIndex) * pointWidth
                    let yLength = max(0.5,halfHeight * CGFloat(pointValue))
                    path.move(to: CGPoint(x: xPos,
                                          y: halfHeight - yLength))
                    path.addLine(to: CGPoint(x: xPos, y: halfHeight + yLength))
                }
            }
            .stroke()
            .drawingGroup()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
