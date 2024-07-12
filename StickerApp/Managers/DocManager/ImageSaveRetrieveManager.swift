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
       let _ = createFolder(folderName: ImageSaveRetrieveManager.foldername)
    }
    
    static let foldername = "UndoRedoFolder"
    
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

    func saveImageToDocumentsFolder(image: UIImage, imageName: String) -> Bool {
        guard let folderURL = createFolder(folderName: ImageSaveRetrieveManager.foldername) else {
            return false
        }
        
        let imageURL = folderURL.appendingPathComponent(imageName).appendingPathExtension("png")
        guard let imageData = image.pngData() else {
            return false
        }
        
        do {
            try imageData.write(to: imageURL)
            return true
        } catch {
            print("Error saving image: \(error)")
            return false
        }
    }

    func retrieveImageFromDocumentsFolder(imageName: String) -> UIImage? {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let imageURL = documentsURL.appendingPathComponent(ImageSaveRetrieveManager.foldername).appendingPathComponent(imageName).appendingPathExtension("png")
        
        if fileManager.fileExists(atPath: imageURL.path) {
            return UIImage(contentsOfFile: imageURL.path)
        } else {
            print("Image not found at path: \(imageURL.path)")
            return nil
        }
    }

    func deleteAllImagesFromFolder() -> Bool {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }
        
        let folderURL = documentsURL.appendingPathComponent(ImageSaveRetrieveManager.foldername)
        
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
}
