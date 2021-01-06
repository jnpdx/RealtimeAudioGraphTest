//
//  ContentView.swift
//  RealtimeAudioGraphTest
//
//  Created by John Nastos on 1/6/21.
//

import SwiftUI
import Combine
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

struct ContentView: View {
    @ObservedObject var dataProvider = DataProvider()
    @State var valuesToDisplay : [Float] = []
    
    var body: some View {
//        VStack {
//            Text("Hello, world!")
//            if valueToDisplay.count > 1 {
//                Text("\(valueToDisplay[0]),\(valueToDisplay[1])")
//            }
//        }
        AudioVisualization(graphData: valuesToDisplay)
        .padding()
        .onReceive(dataProvider.dataPublisher) { newValue in
            //os_log("New value: %f",(Date().timeIntervalSince1970))
            valuesToDisplay = newValue
        }
        .onAppear {
            dataProvider.startGenerating()
        }
    }
}

let kSamplesPerPixel : UInt32 = 40

struct AudioVisualization: View {
    var graphData: [Float]
    
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
                let pointWidth = geometry.size.width / CGFloat(graphData.count)
                let halfHeight = geometry.size.height / 2
                for pointIndex in 0..<graphData.count {//min(5,graphData.count) {
                    let pointValue = graphData[pointIndex]
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
