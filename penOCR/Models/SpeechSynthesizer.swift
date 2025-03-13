

import SwiftUI
import AVFoundation

// Keep your existing SpeechSynthesizer class
class SpeechSynthesizer: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false
    
    func speak(text: String) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
        
        // Stop any ongoing speech
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
    
    func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
        }
    }
    
    func toggleSpeech(text: String) {
            if isSpeaking {
                stopSpeaking()
            } else {
                speak(text: text)
            }
        }
    
    @objc func speechDidFinish() {
        isSpeaking = false
    }
    
    func speakButton(text: String) -> some View {
            Button(action: {
                self.toggleSpeech(text: text)
            }) {
                HStack {
                    Image(systemName: isSpeaking ? "speaker.slash" : "speaker.wave.2")
                    Text(isSpeaking ? "Stop" : "Speak")
                }
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
}

struct TranscriptionView: View {
    @State private var transcribedText: String = "Your transcribed text will appear here."
    @StateObject private var speechSynthesizer = SpeechSynthesizer()

    var body: some View {
        VStack {
            Text(transcribedText)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .border(Color.gray, width: 1)
            
            // Simple speech button
            Button(action: {
                speechSynthesizer.toggleSpeech(text: transcribedText)
            }) {
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
