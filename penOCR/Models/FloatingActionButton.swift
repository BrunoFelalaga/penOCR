//
//  FloatingActionButton.swift
//  penOCR2
//
//  Created by Bruno Felalaga  on 3/11/25.
//
import SwiftUI


struct FloatingActionButton: View {
    var icon: String
    var label: String
    var color: Color
    var action: () -> Void
    
    var body: some View {
        VStack {
            Button(action: action) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(color)
                    .cornerRadius(28)
                    .shadow(radius: 5)
            }
            Text(label)
                .font(.caption)
                .foregroundColor(.primary)
        }
    }
}
