//
//  ContentView.swift
//  RealtimeAudioGraphTest
//
//  Created by John Nastos on 1/6/21.
//

import SwiftUI
import Combine

struct ContentView: View {
    var audioInputController = AudioInputController()
    @State var timestamp : UInt64 = 0
    
    @ObservedObject var fileController = AudioFileController()
    
    @State private var cancelables = Set<AnyCancellable>()
    
    var body: some View {
        VStack {
            AudioVisualization(timestamp: timestamp,
                               bufferData: audioInputController.audioBuffer,
                               startPoint: 0,
                               endPoint: audioInputController.audioBuffer.count)
//            AudioVisualization(timestamp: 0,
//                               bufferData: fileController.audioBuffer,
//                               startPoint: 0,
//                               endPoint: min(500,fileController.audioBuffer.count))
            AudioVisualizationScroller(bufferData: fileController.audioBuffer)
            AudioVisualization(timestamp: 0,
                               bufferData: fileController.audioBuffer,
                               startPoint: min(1000,fileController.audioBuffer.count),
                               endPoint: min(4000,fileController.audioBuffer.count))
        }
        .padding()
        
        
        .onAppear {
            if let pcmBuffer = fileController.loadAudioFile(Bundle.main.url(forResource: "OriginalAudio", withExtension: "m4a")!) {
                fileController.loadAndProcessBuffer(pcmBuffer: pcmBuffer)
            }
            audioInputController.setupEngine()
            audioInputController.start()
            cancelables.insert(
                audioInputController
                    .dataPublisher
                    .receive(on: RunLoop.main)
                    .sink { _ in
                        self.timestamp = mach_absolute_time()
                }
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
