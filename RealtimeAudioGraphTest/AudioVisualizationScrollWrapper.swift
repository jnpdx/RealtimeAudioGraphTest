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
    @State private var endPoint: Int = 0
    
    var body: some View {
        ZStack {
            AudioVisualization(timestamp: 0,
                               bufferData: bufferData,
                               startPoint: startPoint,
                               endPoint: endPoint)
            AudioVisualizationScroller_ScrollView(bufferLength: bufferData.count,
                                                  startPoint: $startPoint, endPoint: $endPoint)
        }
    }
}

struct AudioVisualizationScroller_ScrollView : UIViewRepresentable {

    typealias UIViewType = UIScrollView
    
    var bufferLength : Int
    var startPoint : Binding<Int>
    var endPoint: Binding<Int>
    
    class Coordinator : NSObject, UIScrollViewDelegate, UIGestureRecognizerDelegate {
        var bufferLength : Int
        var startPoint : Binding<Int>
        var endPoint: Binding<Int>
        
        var scrollView : UIScrollView?
        
        private var zoomScaleStart : CGFloat = 0
        private var zoomScale: CGFloat = 0.5
        
        var scrollViewWidth: CGFloat = 0
        var scrollOffsetPercentage : CGFloat = 0
        
        private var ignoreScrollEvents = false
        
        init(start: Binding<Int>, end: Binding<Int>, bufferLength: Int) {
            self.bufferLength = bufferLength
            self.startPoint = start
            self.endPoint = end
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard !ignoreScrollEvents else {
                return
            }
            
            scrollOffsetPercentage = scrollView.contentOffset.x / scrollView.contentSize.width
            DispatchQueue.main.async {
                self.updateBindings()
            }
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
        
        @objc func pinchGesture(_ gc: UIPinchGestureRecognizer) {
            switch gc.state {
            case .began:
                zoomScaleStart = zoomScale
                ignoreScrollEvents = true
            case .cancelled, .ended, .failed:
                ignoreScrollEvents = false
            default:
                break
            }
            
            var newZoom : CGFloat = zoomScale
            
            switch gc.scale {
            case let scale where scale == 1.0:
                newZoom = 1.0
            case let scale where scale < 1.0:
                newZoom = max(scale * zoomScaleStart, 0.2)
            case let scale where scale > 1.0:
                newZoom = min(scale * zoomScaleStart, 3.0)
            default:
                break
            }
            
            zoomScale = newZoom
            
            DispatchQueue.main.async {
                self.updateBindings()
            }
        }
        
        func updateBindings() {
            guard let scrollView = scrollView else {
                fatalError()
            }
            //1000 pts of data
            //normally 1000pts wide
            //window = 200pts wide
            //zoom: 0.5
            //turns into 500pts wide
            //content offset : 25%
            //originally should have been 250-350
            //with zoom, should be 125-325
            
            let contentWidth = CGFloat(bufferLength) * zoomScale
            scrollView.contentSize = CGSize(width: contentWidth,
                                            height: scrollView.frame.size.height)
            
            
            let startPoint = CGFloat(bufferLength) * scrollOffsetPercentage
            let endPoint = startPoint + scrollView.frame.size.width / zoomScale
            
            self.startPoint.wrappedValue = Int(startPoint)
            self.endPoint.wrappedValue = min(bufferLength,Int(endPoint))
        }
    }
    
    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(start: startPoint, end: endPoint, bufferLength: bufferLength)
        return coordinator
    }
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        let pinchGR = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.pinchGesture(_:)))
        pinchGR.delegate = context.coordinator
        scrollView.addGestureRecognizer(pinchGR)
        context.coordinator.scrollView = scrollView
        DispatchQueue.main.async {
            context.coordinator.updateBindings()
        }
        return scrollView
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.scrollViewWidth = uiView.frame.width
        context.coordinator.bufferLength = bufferLength
        DispatchQueue.main.async {
            context.coordinator.updateBindings()
        }
    }
}
