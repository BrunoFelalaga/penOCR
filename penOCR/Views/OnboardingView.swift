//
//  OnboardingView.swift
//  penOCR2
//
//  Created by Bruno Felalaga  on 3/12/25.


import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    
    var body: some View {
        TabView {
            OnboardingPage(
                systemName: "doc.text.viewfinder",
                title: "Capture Handwriting",
                description: "Take a photo of any handwritten note"
            )
            
            OnboardingPage(
                systemName: "text.bubble",
                title: "Convert to Text",
                description: "Instantly transform handwriting into editable text"
            )
            
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


struct OnboardingPage: View {
    let systemName: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: systemName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 20))
                .foregroundColor(.secondary)
                .padding(.bottom, 30)
        }
    }
}

struct FinalOnboardingPage: View {
    let systemName: String
    let title: String
    let description: String
    @Binding var showOnboarding: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: systemName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    showOnboarding = false
                }
                UserDefaults.standard.set(true, forKey: "onboardingComplete")
            }) {
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
