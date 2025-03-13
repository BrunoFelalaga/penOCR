//
//  PhotoDeletable.swift
//  camApp
//
//  Created by Bruno Felalaga  on 3/10/25.
//


import SwiftUI
import CoreData

// Protocol for photo deletion functionality
protocol PhotoDeletable {
    func deletePhoto(_ photo: ImageData, from context: NSManagedObjectContext)
    func confirmDeletion(for photo: ImageData, in context: NSManagedObjectContext) -> Alert
}

extension PhotoDeletable {
    func deletePhoto(_ photo: ImageData, from context: NSManagedObjectContext) {
        context.delete(photo)
        do {
            try context.save()
            print("Photo deleted successfully")
        } catch {
            print("Error deleting photo: \(error)")
        }
    }
    
    func confirmDeletion(for photo: ImageData, in context: NSManagedObjectContext) -> Alert {
        Alert(
            title: Text("Delete Photo"),
            message: Text("Are you sure you want to delete this photo? This action cannot be undone."),
            primaryButton: .destructive(Text("Delete")) {
                deletePhoto(photo, from: context)
            },
            secondaryButton: .cancel()
        )
    }
}
