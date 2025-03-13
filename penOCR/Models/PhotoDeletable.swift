//
//  PhotoDeletable.swift
//  camApp
//
//  Created by Bruno Felalaga  on 3/10/25.
//


import SwiftUI
import CoreData

/// PhotoDeletable: Protocol defining photo deletion capabilities
/// Provides standard implementation for deleting photos with confirmation
protocol PhotoDeletable {
    /// Removes photo from Core Data context and saves changes
    func deletePhoto(_ photo: ImageData, from context: NSManagedObjectContext)
    
    // Creates standardized confirmation alert with delete/cancel options
    func confirmDeletion(for photo: ImageData, in context: NSManagedObjectContext) -> Alert
}

extension PhotoDeletable {
    
    /// Removes photo from Core Data context and saves changes
    func deletePhoto(_ photo: ImageData, from context: NSManagedObjectContext) {
        context.delete(photo)
        do {
            try context.save() // Persist changes to storage
            print("Photo deleted successfully")
        } catch {
            print("Error deleting photo: \(error)")
        }
    }
    
    
    // Creates standardized confirmation alert with delete/cancel options
    func confirmDeletion(for photo: ImageData, in context: NSManagedObjectContext) -> Alert {
        Alert(
            title: Text("Delete Photo"),
            message: Text("Are you sure you want to delete this photo? This action cannot be undone."),
            primaryButton: .destructive(Text("Delete")) {
                deletePhoto(photo, from: context) // Call delete function when confirmed
            },
            secondaryButton: .cancel()
        )
    }
}
