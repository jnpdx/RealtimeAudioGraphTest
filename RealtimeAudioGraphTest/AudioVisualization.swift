//
//  AudioVisualization.swift
//  RealtimeAudioGraphTest
//
//  Created by John Nastos on 1/7/21.
//

import Foundation
import SwiftUI

let kSamplesPerPixel : UInt32 = 30

struct AudioVisualization: View {
    var timestamp : UInt64
    var bufferData : [Float]
    var startPoint : Int
    var endPoint : Int
    
    var body: some View {
        GeometryReader { geometry in
            
            //TODO: zoom
            //draw a grid every 1000 samples
            Path { path in
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
                let pointWidth = geometry.size.width / CGFloat(endPoint - startPoint)
                let halfHeight = geometry.size.height / 2
                guard endPoint > startPoint else {
                    return
                }
                for pointIndex in 0..<(endPoint - startPoint) {
                    guard startPoint + pointIndex > 0 else {
                        continue
                    }
                    let pointValue = bufferData[startPoint + pointIndex]
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
