//
//  ModelStore.swift
//  TenorGif
//
//  Created by Paul Ossenbruggen on 6/21/17.
//  Copyright © 2017 Paul Ossenbruggen. All rights reserved.
//

import Foundation

class ModelStore: NSObject {
    var results: [AssetModel] = []
    @objc dynamic var updated: Bool = false // this is to work around bug in setting results.
    var kvo : NSKeyValueObservation!
    
     func process(_ data: Data) -> CompletionData<AssetModel> {
        let decoder = JSONDecoder()
        do {
            let results = try decoder.decode(AssetModel.self, from: data)
            if self.results.count < 2 {
                self.results.append(results)
            }else {
                self.results[1] = results
            }
            self.updated = true
            return CompletionData.success(results)
        } catch let error {
            return CompletionData.error(error)
        }
    }
}
