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
    
    @State private var cancelables = Set<AnyCancellable>()
    
    var body: some View {
        AudioVisualization(timestamp: timestamp,
                           bufferData: audioInputController.audioBuffer,
                           startPoint: 0,
                           endPoint: audioInputController.audioBuffer.count)
        .padding()
        .onAppear {
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
