//
//  LaunchScreenView.swift
//  penOCR
//
//  Created by Bruno Felalaga  on 3/5/25.
//


import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            Color.purple
                .ignoresSafeArea()
            VStack(spacing: 20) {
                Spacer()
                
                // App icon image
                Image(systemName: "doc.text.viewfinder")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                
                Text("penOCR")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
            }
        }
    }
}
