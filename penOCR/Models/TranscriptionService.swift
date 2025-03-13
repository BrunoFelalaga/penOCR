//
//  TranscriptionService.swift
//  penOCR
//
//  Created by Bruno Felalaga  on 3/6/25.


import SwiftUI
import Vision

class TranscriptionService: ObservableObject {
    @Published var recognizedText = ""
    @Published var isRecognizing = false
    
    // Function to recognize text from the given UIImage using Vision framework
    func recognizeText(from image: UIImage) {
        guard let cgImage = image.cgImage else { // Convert to CGImage. Handle error if it fails
            print("Failed to get CGImage from UIImage")
            self.isRecognizing = false
            return
        }


        // Create a new Vision image-request handler
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        // Create a Vision new request to recognize text
        let request = VNRecognizeTextRequest { [weak self]  request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation], // observations are an array
                  error == nil else {
                print("Text recognition error: \(error?.localizedDescription ?? "Unknown Error")")
                DispatchQueue.main.async {
                        self?.isRecognizing = false
                }
                return
            }
            
            // Extract recognized text strings from observations, with highest confidence
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            
            let recognizedTextLocal = recognizedStrings.joined(separator: "\n")
            
            // Update state on the main thread after recognition completes
            DispatchQueue.main.async {
                self?.recognizedText = recognizedTextLocal
                self?.isRecognizing = false
            }
        }

        // Set text recognition options for accuracy and language correction
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        do {
            try requestHandler.perform([request])
        } catch {
            print("Failed to perform image request: \(error)")
            DispatchQueue.main.async {
                self.isRecognizing = false
            }
        }

    }

    
    func reset() {
        recognizedText = ""
        isRecognizing = false
    }
    
}



