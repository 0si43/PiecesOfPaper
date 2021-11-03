//
//  NotesGrid.swift
//  PiecesOfPaper
//
//  Created by nakajima on 2021/10/31.
//  Copyright © 2021 Tsuyoshi nakajima. All rights reserved.
//

import SwiftUI
import PencilKit

struct NotesGrid: View {
    @ObservedObject var viewModel = ViewModel()
    let gridItem = GridItem(.adaptive(minimum: 250), spacing: 50.0)
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Spacer(minLength: 30.0)
                LazyVGrid(columns: [gridItem], spacing: 60.0) {
                    ForEach((0..<viewModel.drawings.count), id: \.self) { index in
                        NavigationLink(destination: Canvas(drawing: viewModel.drawings[index])) {
                            Image(uiImage: viewModel.drawings[index].image(from: viewModel.drawings[index].bounds, scale: 1.0))
                                .resizable()
                                .frame(width: 250.0, height: 190.0)
                                .scaledToFit()
                                .background(Color(UIColor.secondarySystemBackground))
                                .shadow(radius: 5.0)
                        }
                    }
                }
            }
            .padding([.leading, .trailing])
            .navigationBarItems(trailing:
                Button(action : new){
                    Image(systemName: "plus")
                }
            )
            .overlay(
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { scrollToBottom(proxy: proxy) }) {
                            Image(systemName: "arrow.down.circle")
                                .resizable()
                                .foregroundColor(Color.blue.opacity(0.2))
                                .frame(width: 100.0, height: 100.0)
                                .padding()
                                
                        }
                    }
                }
            )
        }
    }
    
    func new() {
        print("temp")
    }
    
    func scrollToBottom(proxy: ScrollViewProxy) {
        proxy.scrollTo(viewModel.drawings.count - 1, anchor: .bottom)
    }
}

struct NotesGrid_Previews: PreviewProvider {
    static var previews: some View {
        NotesGrid()
    }
}
