//
//  AssetModel.swift
//
//  Created by Paul Ossenbruggen on 6/20/17.
//  Copyright © 2017 Paul Ossenbruggen. All rights reserved.
//

import Foundation

protocol UpdateDelegate {
    func update()
}

// Swift 4 decodable is quite nice.
enum AssetModelError: Error {
    case jsonDecodeError
}

struct AssetModel: Decodable {
    
    struct Nanogif: Decodable {
        let url: URL
        let preview: URL
    }
    
    struct Media: Decodable {
        let nanogif: Nanogif
    }
    
    struct Result: Decodable {
        let media: [Media]
        let title: String
    }
    
    let results: [Result]
}
