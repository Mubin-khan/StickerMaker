//
//  ImageSaveRetrieveManager.swift
//  StickerApp
//
//  Created by Mubin Khan on 7/12/24.
//

import UIKit

class ImageSaveRetrieveManager {
    static let shared = ImageSaveRetrieveManager()
    private init(){
       let _ = createFolder(folderName: ImageSaveRetrieveManager.unodRedofoldername)
       let _ = createFolder(folderName: ImageSaveRetrieveManager.imageStickersUrlFoldername)
    }
    
    static let unodRedofoldername = "UndoRedoFolder"
    static let imageStickersUrlFoldername = "SavedStickersUrl"
    
    func createFolder(folderName: String) -> URL? {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let folderURL = documentsURL.appendingPathComponent(folderName)
        
        if !fileManager.fileExists(atPath: folderURL.path) {
            do {
                try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating folder: \(error)")
                return nil
            }
        }
        
        return folderURL
    }

    func saveImageToDocumentsFolder(image: UIImage, imageName: String, foldername : String) -> URL? {
        guard let folderURL = createFolder(folderName: foldername) else {
            return nil
        }
        
        let imageURL = folderURL.appendingPathComponent(imageName).appendingPathExtension("png")
        guard let imageData = image.pngData() else {
            return nil
        }
        
        do {
            try imageData.write(to: imageURL)
            return imageURL
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }

    func retrieveImageFromDocumentsFolder(imageName: String, foldername : String) -> UIImage? {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let imageURL = documentsURL.appendingPathComponent(foldername).appendingPathComponent(imageName).appendingPathExtension("png")
        
        if fileManager.fileExists(atPath: imageURL.path) {
            return UIImage(contentsOfFile: imageURL.path)
        } else {
            print("Image not found at path: \(imageURL.path)")
            return nil
        }
    }

    func deleteAllImagesFromFolder(foldername : String) -> Bool {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }
        
        let folderURL = documentsURL.appendingPathComponent(foldername)
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
            for fileURL in fileURLs {
                try fileManager.removeItem(at: fileURL)
            }
            return true
        } catch {
            print("Error deleting files: \(error)")
            return false
        }
    }
    
    func retrieveAllImagesFromFolder(folderName: String) -> [URL] {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return []
        }
        
        let folderURL = documentsURL.appendingPathComponent(folderName)
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
            return fileURLs
        } catch {
            print("Error retrieving images: \(error)")
            return []
        }
    }
}
