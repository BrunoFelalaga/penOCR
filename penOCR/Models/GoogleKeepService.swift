//
//  GoogleKeepService.swift
//  penOCR2
//
//  Created by Bruno Felalaga  on 3/10/25.
//


import SwiftUI


// GoogleKeepService: Service for exporting transcriptions to Google Keep
// Handles clipboard and app/web redirection
class GoogleKeepService {
    
    // Exports text content to Google Keep with title with multiple paths for Keep integration
    static func saveToGoogleKeep(title: String, text: String) {
        
        // Copy to clipboard
        let combinedText = "\(title)\n\n\(text)"
        UIPasteboard.general.string = combinedText
        
        // Create alert with options
        let alert = UIAlertController(
            title: "Text Copied",
            message: "Content has been copied to clipboard",
            preferredStyle: .alert
        )
        
        // Attempts at saving to google-keep
        // 1: Try Google Keep app via URL scheme
        alert.addAction(UIAlertAction(title: "Open Keep App", style: .default) { _ in
            if let keepAppURL = URL(string: "gkeep://") {
                UIApplication.shared.open(keepAppURL, options: [:]) { success in
                    if !success {
                        showKeepWebFallbackAlert()
                    }
                }
            } else {
                showKeepWebFallbackAlert()
            }
        })
        
        // 2: Direct to web version
        alert.addAction(UIAlertAction(title: "Open Keep Website", style: .default) { _ in
            openKeepWebsite()
        })
        
        
        // Cancel option dismisses dialog without further action
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Find and use app's root view controller to present the alert/
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
    
    
    // Shows fallback alert when Keep app isn't installed with web version as alternative
    private static func showKeepWebFallbackAlert() {
        let fallbackAlert = UIAlertController(
            title: "Keep App Not Found",
            message: "Would you like to open Google Keep in your browser instead?",
            preferredStyle: .alert
        )
        
        // Option to open web version
        fallbackAlert.addAction(UIAlertAction(title: "Open in Browser", style: .default) { _ in
            openKeepWebsite()
        })
        
        
        // Cancel option dismisses dialog
        fallbackAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Present fallback alert on root view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(fallbackAlert, animated: true)
        }
    }

    // Opens Google Keep website in default browser. Tries short URL first, then falls back to main Keep URL
    private static func openKeepWebsite() {
        // Try direct note creation URL first
        if let keepNewURL = URL(string: "https://keep.new") {
            UIApplication.shared.open(keepNewURL, options: [:]) { success in
                if !success, let keepURL = URL(string: "https://keep.google.com") {
                    UIApplication.shared.open(keepURL, options: [:], completionHandler: nil)
                }
            }
        }
    }
}
