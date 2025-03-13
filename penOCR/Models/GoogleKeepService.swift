//
//  GoogleKeepService.swift
//  penOCR2
//
//  Created by Bruno Felalaga  on 3/10/25.
//


import SwiftUI

class GoogleKeepService {
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
        // 1: Try Google Keep app
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
        
        // Option 3: Just copy (already done)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
    
    private static func showKeepWebFallbackAlert() {
        let fallbackAlert = UIAlertController(
            title: "Keep App Not Found",
            message: "Would you like to open Google Keep in your browser instead?",
            preferredStyle: .alert
        )
        
        fallbackAlert.addAction(UIAlertAction(title: "Open in Browser", style: .default) { _ in
            openKeepWebsite()
        })
        
        fallbackAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(fallbackAlert, animated: true)
        }
    }

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
