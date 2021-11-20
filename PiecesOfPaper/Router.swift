//
//  Router.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/11/19.
//  Copyright © 2021 Tsuyoshi nakajima. All rights reserved.
//

import Foundation
import SwiftUI
import PencilKit

final public class Router {
    public static let shared = Router()
    private var isShowCanvas: Binding<Bool>!
    private var drawing: Binding<PKDrawing>!
    
    private init() { }
    
    public func setStateValue(isShowCanvas: Binding<Bool>) {
        self.isShowCanvas = isShowCanvas
    }
    
    public func toggleStateValue() {
        isShowCanvas?.wrappedValue.toggle()
    }
    
    public func setDrawing(drawing: Binding<PKDrawing>) {
        self.drawing = drawing
    }
    
    public func updateDrawing(drawing: PKDrawing) {
        self.drawing.wrappedValue = drawing
    }
}
