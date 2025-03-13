import SwiftUI
import Vision
import PhotosUI

struct ContentView: View {
    
    @StateObject private var transcriptionService = TranscriptionService()
    
    private var recognizedText: String { transcriptionService.recognizedText }
    private var isRecognizing: Bool { transcriptionService.isRecognizing }
    
    @State private var isShowingCameraView = false
    
    @StateObject private var speechSynthesizer = SpeechSynthesizer()
    
    @State private var transcriptionTitle = "Untitled"
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showSaveDialog = false
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var inputImage: UIImage? = UIImage(named: "test_image_1")
    @State private var autoTranscribe = false
    
    init(inputImage: UIImage? = nil, autoTranscribe: Bool = false) {
        _inputImage = State(initialValue: inputImage)

        _autoTranscribe = State(initialValue: autoTranscribe)
    }

    
    var body: some View {
        NavigationView {
            VStack {
                if let image = inputImage {
                    if let cgImage = image.cgImage {
                        Image(cgImage, scale: 1.0, orientation: .right, label: Text("Captured Photo"))
                            .resizable()
                            .scaledToFit()
                            .padding()
                    }
                }
                else {
                    Text("No Image loaded")
                        .padding()
                    
                    Image(systemName: "camera")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                        .padding()
                    
                    Text("Upload a handwritten note")
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button(action: {
                        isShowingCameraView = true
                    }) {
                        Image(systemName: "camera.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                    }
                    .padding()

                }
                
                
                // If recognized text is available, display it
                if !recognizedText.isEmpty {
                    ScrollView { // Make text scrollable if its long
                        Text("Recognized Text:").font(.headline).padding(.top)
                        
                        Text(recognizedText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .padding()
                        
                    }
                    
                    
                }
                HStack {
                    Spacer().frame(width: 1)
                    
                    FloatingActionButton(icon: "arrow.left", label: "Back", color: .black.opacity(0.7)) {
                        dismiss()
                    }
                    
                    Spacer()
                    
                    FloatingActionButton(
                        icon: "doc.text.viewfinder",
                        label: "re-transcribe",
                        color: .black.opacity(0.7)
                    ) {
                        if let image = inputImage {
                            transcriptionService.recognizeText(from: image)
                        }
                    }
                    .disabled(inputImage == nil)
                    
                    
                    
                    Spacer()
                    FloatingActionButton(
                        icon: speechSynthesizer.isSpeaking ? "speaker.slash" : "speaker.wave.2",
                        label: speechSynthesizer.isSpeaking ? "Stop" : "Speak",
                        color: .black.opacity(0.7)
                    ) {
                        speechSynthesizer.toggleSpeech(text: recognizedText)
                    }
                    
                    
                    Spacer()
                    
                    FloatingActionButton(
                        icon: "square.and.arrow.down",
                        label: "save",
                        color: .black.opacity(0.7)
                    ) {
                        // Show an alert with save options
                        let alert = UIAlertController(
                            title: "Save Options",
                            message: "Choose where to save your transcription",
                            preferredStyle: .alert
                        )
                        
                        alert.addAction(UIAlertAction(title: "Save in App", style: .default) { _ in
                            showSaveDialog = true
                        })
                        
                        alert.addAction(UIAlertAction(title: "Save to Google Keep", style: .default) { _ in
                            GoogleKeepService.saveToGoogleKeep(title: transcriptionTitle, text: recognizedText)
                        })
                        
                        alert.addAction(UIAlertAction(title: "Copy Only", style: .default) { _ in
                                UIPasteboard.general.string = recognizedText
                            })
                        
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                        
                        // Present the alert
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let rootViewController = windowScene.windows.first?.rootViewController {
                            rootViewController.present(alert, animated: true)
                        }
                    }
                    
                    Spacer().frame(width: 1)

                }
                                
            }
            .padding()
            
            .toolbar {

                ToolbarItem(placement: .principal) {
                    HStack {
                        Text("Handwriting to Text")
                            .font(.headline)
                            .padding(.trailing, 40)
                            
                        Button(action: {
                            transcriptionService.reset()
                            transcriptionTitle = "Untitled"
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
            .navigationBarBackButtonHidden(true)

            .onAppear {
                if autoTranscribe && inputImage != nil {
                    transcriptionService.recognizeText(from: inputImage!)
                }
            }
            .sheet(isPresented: $showSaveDialog) {
                VStack(spacing: 20) {
                    Text("Save Transcription").font(.headline)
                    
                    TextField("Title", text: $transcriptionTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    HStack {
                        Button("Cancel") {
                            showSaveDialog = false
                        }
                        .padding()
                        
                        Button("Save") {
                            saveTranscription()
                            showSaveDialog = false
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding()
                .frame(width: 300, height: 200)
            }

        }
    }
        
    func saveTranscription() {
        
        let newTranscription = Transcription(context: viewContext)
        newTranscription.id = UUID()
        newTranscription.text = recognizedText
        newTranscription.title = transcriptionTitle
        newTranscription.createdAt = Date()
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving: \(error)")
        }
    }
    
    
    func requestPhotoPermission() {
        PHPhotoLibrary.requestAuthorization { status in
            
        }
    }
    

}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
