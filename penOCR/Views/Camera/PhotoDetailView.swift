
import SwiftUI
import CoreData

struct PhotoDetailView: View, PhotoDeletable {
    var imageData: Data
    @Environment(\.presentationMode) var presentationMode
    var onDelete: (() -> Void)?
    var onBack: (() -> Void)?
    
    init(imageData: Data, onDelete: (() -> Void)? = nil, onBack: (() -> Void)? = nil) {
        self.imageData = imageData
        self.onDelete = onDelete
        self.onBack = onBack
    }
    
    
    
    var body: some View {
        ZStack {
            Color.black

            if let uiImage = UIImage(data: imageData) {
              
                if let cgImage = uiImage.cgImage {
                    Image(cgImage, scale: 1.0, orientation: .right, label: Text("Captured Photo"))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .edgesIgnoringSafeArea(.all)
                }
            } else {
                Text("Image failed to load")
                    .foregroundColor(.white)
            }
            
            VStack {
                            HStack(spacing: 20) {
                                Spacer().frame(width: 10)
                                FloatingActionButton(icon: "arrow.left", label: "Back", color: .black.opacity(0.7)) {

                                    if let onBack = onBack {
                                            onBack()
                                        } else {
                                            presentationMode.wrappedValue.dismiss()
                                        }
                                }.toolbar(.visible, for: .tabBar)
                                Spacer()
                                if let onDelete = onDelete {
                                    FloatingActionButton(icon: "trash", label: "Delete", color: .red.opacity(0.8)) {
                                        onDelete()
                                    }
                                    Spacer().frame(width: 10)
                                }
                            }
                            .padding(.top, 30)
                Spacer()
                        }
           
                    }
                    .edgesIgnoringSafeArea(.all)
                    
                    
    }
    
    

}

struct PhotoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let size = CGSize(width: 300, height: 400)
        UIGraphicsBeginImageContext(size)
        UIColor.blue.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let placeholderImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        let imageData = placeholderImage.jpegData(compressionQuality: 0.8)!
        
        return PhotoDetailView(imageData: imageData)
    }
}
