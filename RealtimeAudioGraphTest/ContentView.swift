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
    //@State var timestamp : UInt64 = 0
    @State var audioBuffer = [Float](repeating: 0.0, count: 9000)
    
    @ObservedObject var fileController = AudioFileController()
    
    @State private var cancelables = Set<AnyCancellable>()
    
    var body: some View {
        VStack {
            AudioVisualization(bufferData: audioBuffer,
                               startPoint: 0,
                               endPoint: audioBuffer.count)
            AudioVisualizationScroller(bufferData: fileController.audioBuffer)
//            AudioVisualization(timestamp: 0,
//                               bufferData: fileController.audioBuffer,
//                               startPoint: min(1000,fileController.audioBuffer.count),
//                               endPoint: min(4000,fileController.audioBuffer.count))
        }
        .padding()
        
        
        .onAppear {
            if let pcmBuffer = fileController.loadAudioFile(Bundle.main.url(forResource: "Sweet Georgia Brown", withExtension: "m4a")!) {
                fileController.loadAndProcessBuffer(pcmBuffer: pcmBuffer)
            }
            //audioInputController.setupEngine()
            //audioInputController.start()
            audioInputController
                .dataPublisher
                .receive(on: RunLoop.main) //might have to use DispatchQueue.main for iOS to continue scrolling
                .sink { _ in
                    self.audioBuffer = audioInputController.audioBuffer
                    //self.timestamp = mach_absolute_time()
            }
            .store(in: &cancelables)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
