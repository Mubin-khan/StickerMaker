//
//  UIViewController+Extensions.swift
//  StickerApp
//
//  Created by Mubin Khan on 7/6/24.
//

import UIKit

extension UIViewController {
    public func openAlert(
        title : String,
        message : String,
        alertStyle : UIAlertController.Style,
        actionTitles : [String],
        actionStyles : [UIAlertAction.Style],
        action : [((UIAlertAction) -> Void)]
    ){
        let alertController = UIAlertController(title: title, message: message, preferredStyle: alertStyle)
        
        for (index, indexTitle) in actionTitles.enumerated() {
            let action = UIAlertAction(title: indexTitle, style: actionStyles[index], handler: action[index])
            alertController.addAction(action)
        }
        
        self.present(alertController, animated: true)
    }
}
