//
//  AudioVisualizationScrollWrapper.swift
//  RealtimeAudioGraphTest
//
//  Created by John Nastos on 1/7/21.
//

import Foundation
import UIKit
import SwiftUI

struct AudioVisualizationScroller : View {
    var bufferData : [Float]
    @State private var startPoint : Int = 0
    @State private var scrollerWidth: Int = 0
    @State private var zoom: Double = 1.0
    
    var body: some View {
        ZStack {
            AudioVisualization(timestamp: 0,
                               bufferData: bufferData,
                               startPoint: Int(Double(startPoint) / zoom),
                               endPoint: min(bufferData.count, Int(Double(startPoint + scrollerWidth) / zoom))
            )
            AudioVisualizationScroller_ScrollView(bufferLength: bufferData.count,
                                                  startPoint: $startPoint,
                                                  scrollerWidth: $scrollerWidth,
                                                  zoomBinding: $zoom)
        }
    }
}

struct AudioVisualizationScroller_ScrollView : UIViewRepresentable {

    typealias UIViewType = UIScrollView
    
    var bufferLength : Int
    var startPoint : Binding<Int>
    var scrollerWidth : Binding<Int>
    var zoomBinding: Binding<Double>
    
    class Coordinator : NSObject, UIScrollViewDelegate, UIGestureRecognizerDelegate {
        var startPointBinding : Binding<Int>
        var scrollWidthBinding: Binding<Int>
        var zoomBinding: Binding<Double>
        
        var scrollView : UIScrollView?
        
        private var zoomScaleStart : Double = 0
        
        init(start: Binding<Int>, width: Binding<Int>, zoom: Binding<Double>) {
            self.startPointBinding = start
            self.scrollWidthBinding = width
            self.zoomBinding = zoom
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            DispatchQueue.main.async {
                self.startPointBinding.wrappedValue = Int(scrollView.contentOffset.x)
            }
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
        
        @objc func pinchGesture(_ gc: UIPinchGestureRecognizer) {
            switch gc.state {
            case .began:
                zoomScaleStart = zoomBinding.wrappedValue
            default:
                break
            }
            
            switch gc.scale {
            case let scale where scale == 1.0:
                zoomBinding.wrappedValue = 1.0
            case let scale where scale < 1.0:
                zoomBinding.wrappedValue = max(Double(scale) * zoomScaleStart, 0.2)
            case let scale where scale > 1.0:
                zoomBinding.wrappedValue = min(Double(scale) * zoomScaleStart, 3.0)
            default:
                break
            }
            
            //TODO: recenter?
            
        }
    }
    
    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(start: startPoint, width: scrollerWidth, zoom: zoomBinding)
        return coordinator
    }
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        let pinchGR = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.pinchGesture(_:)))
        pinchGR.delegate = context.coordinator
        scrollView.addGestureRecognizer(pinchGR)
        context.coordinator.scrollView = scrollView
        return scrollView
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        let width = CGFloat(bufferLength) * CGFloat(zoomBinding.wrappedValue)
        if uiView.contentSize.width != width {
            print("Updating scrollview of size: \(uiView.frame) to content width: \(width)")
            uiView.contentSize = CGSize(width: width,
                                        height: uiView.frame.size.height)
            DispatchQueue.main.async {
                scrollerWidth.wrappedValue = Int(uiView.frame.width)
            }
        }
    }
}
