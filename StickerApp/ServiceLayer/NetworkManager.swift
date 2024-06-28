//
//  NetworkManager.swift
//  StickerApp
//
//  Created by Mubin Khan on 6/28/24.
//

import UIKit
import Alamofire

class NetWorkManager : NSObject {
    static let shared = NetWorkManager()
    
    let reachabilityManager = NetworkReachabilityManager()
    
    func isNetworkReachable() -> Bool {
        return reachabilityManager?.isReachable ?? false
    }
    
    private override init() {}
}
