//
//  FloatingActionButton.swift
//  penOCR2
//
//  Created by Bruno Felalaga  on 3/11/25.
//

import SwiftUI

/// FloatingActionButton:  Reusable floating action button component with icon and label
/// Provides consistent styling for app actions with customizable colors
struct FloatingActionButton: View {
    var icon: String
    var label: String
    var color: Color
    var action: () -> Void     // Closure executed when button is tapped
    
    var body: some View {
        VStack {
            // Main button with icon, background and shadow
            Button(action: action) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(color)
                    .cornerRadius(28)
                    .shadow(radius: 5)
            }
            
            // Caption label below the button
            Text(label)
                .font(.caption)
                .foregroundColor(.primary)
        }
    }
}
