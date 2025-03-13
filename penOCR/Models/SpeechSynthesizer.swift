

import SwiftUI
import AVFoundation

// SpeechSynthesizer: Manages text-to-speech functionality with playback controls
// Provides UI components for speech integration in views
class SpeechSynthesizer: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer() // Core speech synthesis engine
    @Published var isSpeaking = false // Tracks current speaking state
    
    
    // Converts text to speech with default audio settings
    func speak(text: String) {
        
        // Configure audio session for playback
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
        
        // Stop any ongoing speech before starting new utterance
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        // Create and configure utterance with defaults
        let utterance = AVSpeechUtterance(string: text)
        
        // Start speaking
        isSpeaking = true
        synthesizer.speak(utterance)
        
        // Set up notification for when speech finishes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(speechDidFinish),
            name: Notification.Name("AVSpeechSynthesizerDidFinishSpeechUtterance"),
            object: synthesizer
        )
    }
    
    
    // Immediately stops any ongoing speech playback
    func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
        }
    }
    
    // Toggles between starting and stopping speech based on current state
    func toggleSpeech(text: String) {
            if isSpeaking {
                stopSpeaking()
            } else {
                speak(text: text)
            }
        }
    
    // Callback for speech completion notification
    @objc func speechDidFinish() {
        isSpeaking = false
    }
    
    
    // Returns a styled button that toggles speech playback with visual state indicators
    func speakButton(text: String) -> some View {
            // Toggle speech button
            Button(action: {
                self.toggleSpeech(text: text)
            }) {
                
                // Toggle speech Button UI with image and text
                HStack {
                    Image(systemName: isSpeaking ? "speaker.slash" : "speaker.wave.2") // Toggle icon based on speech state
                    Text(isSpeaking ? "Stop" : "Speak") // Toggle label based on speech state
                }
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
}



// TranscriptionView: Displays transcribed text with integrated text-to-speech functionality
struct TranscriptionView: View {
    @State private var transcribedText: String = "Your transcribed text will appear here."
    @StateObject private var speechSynthesizer = SpeechSynthesizer()

    var body: some View {
        VStack {
            
            // Text display area with border
            Text(transcribedText)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .border(Color.gray, width: 1)
            
            // Speech playback toggle button
            Button(action: {
                speechSynthesizer.toggleSpeech(text: transcribedText)
            }) {
                
                // Speech playback Button UI with image and text
                HStack {

                    Image(systemName: speechSynthesizer.isSpeaking ? "speaker.slash" : "speaker.wave.2")
                    Text(speechSynthesizer.isSpeaking ? "Stop" : "Speak")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
    }
    
    // Call this when you get new transcription
    func updateTranscribedText(_ newText: String) {
        transcribedText = newText
    }
    
}

// Preview
struct TranscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        TranscriptionView()
    }
}
