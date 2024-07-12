//
//  UndoRedoModel.swift
//  StickerApp
//
//  Created by Mubin Khan on 7/12/24.
//

import Foundation

struct EraseRestoreImageModel : Equatable {
    var imageName : String
}

struct BlurUndoRedoModel : Equatable {
    var isBlur : Bool
    var imageName : String
}
