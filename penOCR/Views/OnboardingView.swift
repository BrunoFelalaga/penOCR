//
//  OnboardingView.swift
//  penOCR2
//
//  Created by Bruno Felalaga  on 3/12/25.



import SwiftUI

/// Onboarding experience for first-time app launch
/// Displays app features with paging navigation
struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    
    var body: some View {
        
        // Page view container
        TabView {
            
            // First page - Capture feature
            OnboardingPage(
                systemName: "doc.text.viewfinder",
                title: "Capture Handwriting",
                description: "Take a photo of any handwritten note"
            )
            
            // Second page - Conversion feature
            OnboardingPage(
                systemName: "text.bubble",
                title: "Convert to Text",
                description: "Instantly transform handwriting into editable text"
            )
            
            // Final page - Save/Share features with completion button
            FinalOnboardingPage(
                systemName: "square.and.arrow.down",
                title: "Save & Share",
                description: "Store transcriptions and share with other apps",
                showOnboarding: $showOnboarding
            )
        }
        .tabViewStyle(PageTabViewStyle())
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    }
}


/// Standard onboarding page with icon, title and description
/// Used for all pages except the final one
struct OnboardingPage: View {
    let systemName: String
    let title: String
    let description: String
    
    var body: some View {
        
        // Content layout
        VStack(spacing: 20) {
            Spacer()
            
            // Feature icon
            Image(systemName: systemName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            // Feature title
            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            // Feature description
            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            // Navigation hint
            Image(systemName: "chevron.right")
                .font(.system(size: 20))
                .foregroundColor(.secondary)
                .padding(.bottom, 30)
        }
    }
}


/// Final onboarding page with "Get Started" button
/// Dismisses onboarding and saves completion status
struct FinalOnboardingPage: View {
    let systemName: String
    let title: String
    let description: String
    @Binding var showOnboarding: Bool
    
    var body: some View {
        
        // Content layout
        VStack(spacing: 20) {
            Spacer()
            
            // Feature icon
            Image(systemName: systemName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            
            // Feature title
            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            // Feature description
            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            // Completion button with action to exit onboarding
            Button(action: {
                withAnimation {
                    showOnboarding = false
                }
                
                // Save completion status to prevent showing again
                UserDefaults.standard.set(true, forKey: "onboardingComplete")
            }) {
                // Button styling
                Text("Get Started")
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .padding(.bottom, 40)
        }
    }
}
