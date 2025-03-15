//
//  LaunchScreenView.swift
//  penOCR
//
//  Created by Bruno Felalaga  on 3/5/25.
//


import SwiftUI

/// Launch screen displayed when the app starts
/// Shows app icon and app name with purple background
struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            
            // Background color
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
                
                // App name
                Text("penOCR")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white) 
                
                Spacer()
                
                Text("Bruno Felalaga")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
                                
                Spacer()
            }
        }
    }
}


struct LaunchScreenView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchScreenView()
    }
}
