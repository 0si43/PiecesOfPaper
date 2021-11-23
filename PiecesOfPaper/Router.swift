//
//  Router.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/11/19.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation
import SwiftUI
import PencilKit

final public class Router {
    public static let shared = Router()
    private var isShowCanvas: Binding<Bool>!
    private var drawing: Binding<PKDrawing>!
    
    private init() { }
    
    /// This procedure should been done by initializer, but a singleton instance couldn't have arguments
    public func bind(isShowCanvas: Binding<Bool>, drawing: Binding<PKDrawing>) {
        self.isShowCanvas = isShowCanvas
        self.drawing = drawing
    }

    /// open a full screen canvas and make new drawing data
    public func openNewCanvas() {
        self.drawing.wrappedValue = PKDrawing()
        toggleStateValue()
    }
    
    /// open a full screen canvas with drawing data
    public func openCanvas(drawing: PKDrawing) {
        self.drawing.wrappedValue = drawing
        toggleStateValue()
    }
    
    private func toggleStateValue() {
        isShowCanvas?.wrappedValue.toggle()
    }
}
