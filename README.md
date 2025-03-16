# penOCR: Handwriting Digitization & Note Taking Management App

## Overview
penOCR is a comprehensive iOS application designed for transcribing your handwritten notes and captured images with text into digital text using the iOS Vision Framework. The app provides a seamless workflow from image capture to organization, with strong text processing abilities and multiple options for managing and storing your transcriptions. penOCR is built with SwiftUI and leverages Core Data for persistent storage. The app offers a modern, efficient solution for taking notes by hand or capturing images with text, converting them into digital form and integrating them with other digital notes and documents. penOCR literally brings your 4th Century BC notes taking style to live!

## Key Features

### Camera & Image Processing
- **Camera Controls**: Adjust brightness, toggle flash, control zoom, and set focus points
- **Image Review & Enhancement**: Review captured images with options to crop and adjust before processing
- **Multiple Input Sources**: Capture images directly or import from photo library

### Text Recognition & Processing
- **OCR Engine**: Leverages Vision framework for accurate handwriting recognition
- **Post-Processing**: Edit recognized text to correct any inaccuracies
- **Multi-format Support**: Process text from various handwriting styles and formats

### Voice & Accessibility Features
- **Text-to-Speech Integration**: Listen to your transcriptions with built-in speech synthesis
- **Playback Controls**: Start, stop, and manage speech playback


### Data Management & Organization
- **Core Data Integration**: Persistence layer for reliable storage and retrieval
- **Searchable Archive**: Full-text search across all of your saved transcriptions
- **Flexible Sorting**: Organize by date or title with ascending/descending options
- **Attachment Support**: Add images and documents to transcriptions for reference


### Sharing & External Integration
- **Google Keep Export**: Direct integration with Google Keep for cloud storage
- **Universal Sharing**: Share via text, email, or any app using iOS share sheet
- **Clipboard Support**: Quick copy option for immediate use in other applications

## Technical Architecture

### Frameworks & Technologies
- **SwiftUI**: Modern declarative UI framework for consistent interface across Apple devices
- **Core Data**: Object graph and persistence framework to handle data storage
- **Vision**: Apple's vision framework for OCR processing
- **AVFoundation**: Camera handling and media management
- **AVSpeech**: Text-to-speech synthesis capabilities
- **PhotosUI**: Integration with system photo library
- **QuickLook**: Preview support for various document types

### Core Data Model
The app implements a thoughtful Core Data architecture with entities for:
- **Transcription**: Stores recognized text with metadata -- title and creation date
- **ImageData**: Manages captured and processed images with relationship to source data
- **Attachment**: Supports multiple document types attached to transcriptions

### Key Components
- **MainView**: Tab-based navigation controller managing app workflow
- **CameraView & FrameHandler**: Sophisticated camera interface with real-time processing
- **ContentView**: Central transcription interface with text processing and editing capabilities
- **TranscriptionService**: Handles OCR processing using Vision framework
- **SpeechSynthesizer**: Manages text-to-speech conversion and playback
- **GalleryView**: Visual management of captured images
- **SavedTranscriptionsView**: Organized listing of all transcriptions with search and sort
- **TranscriptionDetailView**: Detailed view and editing capabilities for saved content
- **PhotoReviewView**: Post-capture image review and adjustment




## Setup Notes
- Camera and photo library permissions must be configured in Info.plist
- Core Data model initialization occurs at application launch
- Default persistent store is configured in PersistenceController

### Requirements & Dependencies
- iOS 16.0 or later
- Swift 5.5+
- Xcode 13+
- Camera and photo library permissions required
- CoreData capabilities
- Active Apple Developer account (for testing on physical devices)


### Installation
1. Clone the repository:
   ```
   git clone https://github.com/uchicago-mobi/mpcs51030-2025-winter-final-project-BrunoFelalaga/tree/main
   cd ./penOCR
   ```

2. Open the project in Xcode:
   ```
   open penOCR.xcodeproj
   ```

3. Configure permissions:
   - Ensure camera permissions are set in Info.plist
   - Ensure photo library permissions are set in Info.plist

4. Build and run:
   - Select

# Previews


*Camera View*

![Camera View](screen%20shots/camera%20view.jpeg)

CameraView of the note to be be captured


**PhotoReview View**
![PhotoReview View](screen%20shots/photo%20review%20view.jpeg)

PhotoReviewView gives you these options for reviewing the captured image:
- crop it, 
- proceed to transcribe it, 
- save it in your in-App photo Gallery or 
- return to camera to re-take it.


***Transcription View***

![Transcription View](screen%20shots/transcription%20review.jpeg)

The transcription is presented with options to 
- re-transcribe if you’re not satisfied with the quality, 
- get a speech service so you can quickly listen without having to read everything, and 
- you can save it to your in-App saved transcriptions. 
- you can also return to the PhotoReview page to edit the image for better transcription. 


## Saving Options

![Saving Options](screen%20shots/save%20options.jpeg)

Saving gives options to 
- save it in the app, 
- export to Google Keep, or 
- copy to clipboard to paste in a desired location.

<!--![Camera View](penOCR/screen shots/saved transcriptions.jpeg)-->
## Saved Transcriptions

![Saved Transcriptions](screen%20shots/saved%20transcriptions.jpeg)

With your transcriptions saved in the app, you can return anytime to 
- edit it, 
- get speech service, 
- share it with friends and family,
- attach other related documents including images, and documents( pdfs, .txt, .doc, .docx, .xlx files etc). 
You can have all your notes right here in the same space!



## Further Improvements
- Fix the double 'back' buttons in ContentView. 
    - Application designed to keep floating 'back' button instead of the navigation 'back' button
- Inlcude speech to text transcription for an even more seamless note-taking and record keeping
- Organize transition betweeen views more efficiently and smoothly
- Include options for user to control styles and themes
- Improve cropping, zooming  and focus features
- Add selfie camera

- VERY IMPORTANTLY: 
    - Use a higher accuracy transcriber than Vision. 
    Currently vision gets a couple of characters wrong even with the most legible handwriting and for some images with digital text. 
    Vision also gives accuracy by lines and they mostly come as confidence values of 1.0
    - Highlight transcriptions of confidencee lower than 0.5 so user attention is drawn to those for immediate edition/correction
    - Incorporate a feature that learns user's handwritting as the saved gallery of handwritting images grows. This will help with even higher accuracy of transcription tailored to the user's handwriting.
