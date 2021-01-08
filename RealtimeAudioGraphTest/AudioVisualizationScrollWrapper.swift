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
    
    var body: some View {
        ZStack {
            AudioVisualization(timestamp: 0,
                               bufferData: bufferData,
                               startPoint: startPoint,
                               endPoint: min(bufferData.count, startPoint + scrollerWidth))
            AudioVisualizationScroller_ScrollView(bufferLength: bufferData.count,
                                                  startPoint: $startPoint,
                                                  scrollerWidth: $scrollerWidth)
        }
    }
}

struct AudioVisualizationScroller_ScrollView : UIViewRepresentable {

    typealias UIViewType = UIScrollView
    
    var bufferLength : Int
    var startPoint : Binding<Int>
    var scrollerWidth : Binding<Int>
    
    class Coordinator : NSObject, UIScrollViewDelegate {
        var startPointBinding : Binding<Int>
        var scrollWidthBinding: Binding<Int>
        
        init(start: Binding<Int>, width: Binding<Int>) {
            self.startPointBinding = start
            self.scrollWidthBinding = width
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            startPointBinding.wrappedValue = Int(scrollView.contentOffset.x)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(start: startPoint, width: scrollerWidth)
        return coordinator
    }
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        return scrollView
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        if uiView.contentSize.width != CGFloat(bufferLength) {
            print("Updating scrollview of size: \(uiView.frame)")
            uiView.contentSize = CGSize(width: CGFloat(bufferLength),
                                        height: uiView.frame.size.height)
            DispatchQueue.main.async {
                scrollerWidth.wrappedValue = Int(uiView.frame.width)
            }
        }
    }
}
