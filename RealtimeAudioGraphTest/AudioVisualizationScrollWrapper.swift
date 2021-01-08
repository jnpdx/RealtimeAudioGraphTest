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
        var scrollOffsetPercentage : CGFloat = 0
        
        private var ignoreScrollEvents = false
        
        init(start: Binding<Int>, width: Binding<Int>, zoom: Binding<Double>) {
            self.startPointBinding = start
            self.scrollWidthBinding = width
            self.zoomBinding = zoom
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard !ignoreScrollEvents else {
                return
            }
            
            scrollOffsetPercentage = scrollView.contentOffset.x / scrollView.contentSize.width
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
                ignoreScrollEvents = true
            case .cancelled, .ended, .failed:
                ignoreScrollEvents = false
            default:
                break
            }
            
            var newZoom : Double = zoomBinding.wrappedValue
            
            switch gc.scale {
            case let scale where scale == 1.0:
                newZoom = 1.0
            case let scale where scale < 1.0:
                newZoom = max(Double(scale) * zoomScaleStart, 0.2)
            case let scale where scale > 1.0:
                newZoom = min(Double(scale) * zoomScaleStart, 3.0)
            default:
                break
            }
            
            zoomBinding.wrappedValue = newZoom
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
        if uiView.contentSize.width.rounded(.up) != width.rounded(.up) {
            //print("Updating scrollview of size: \(uiView.frame) to content width: \(width)")
            
            DispatchQueue.main.async {
                uiView.contentSize = CGSize(width: width,
                                            height: uiView.frame.size.height)
                uiView.contentOffset.x = width * context.coordinator.scrollOffsetPercentage
                startPoint.wrappedValue = Int(uiView.contentOffset.x)
                scrollerWidth.wrappedValue = Int(uiView.frame.width)
            }
            
        }
    }
}
