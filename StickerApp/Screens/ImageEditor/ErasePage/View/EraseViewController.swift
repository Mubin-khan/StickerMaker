//
//  EraseViewController.swift
//  StickerApp
//
//  Created by Mubin Khan on 7/6/24.
//

import UIKit

class EraseViewController: UIViewController {

    @IBOutlet weak var contentImageView: UIImageView!
    var contentImg : UIImage
    
    init(contentImg: UIImage) {
        self.contentImg = contentImg
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.isNavigationBarHidden = true
        contentImageView.image = contentImg
    }


    @IBAction func magicAction(_ sender: Any) {
        guard let baseImage = CIImage(image: contentImg), let maskCiImage = AppleBgRemover.shared.applyPersonSegmentation(ciImage: baseImage) else {
            
            openAlert(title: "Magic", message: "Sorry, we couldn't identify the image to crop", alertStyle: .alert, actionTitles: ["OK"], actionStyles: [.default], action: [{ _ in
                self.gotoBGRemover(maskimg: nil)
            }])
            
            return
        }
        let maskImage = UIImage(ciImage: maskCiImage)
    
        gotoBGRemover(maskimg: maskImage)
    }
    
    func gotoBGRemover(maskimg : UIImage?){
        let vc = BGRemoveViewController(fullImage: contentImg, maskImage: maskimg)
        let navVC = UINavigationController(rootViewController: vc)
        navVC.isNavigationBarHidden = true
        navVC.modalPresentationStyle = .fullScreen
        self.present(navVC, animated: true, completion: nil)
    }
    
    @IBAction func brushAction(_ sender: Any) {
        let vc = BrushViewController(fullImage: contentImg)
        let navVC = UINavigationController(rootViewController: vc)
        navVC.isNavigationBarHidden = true
        navVC.modalPresentationStyle = .fullScreen
        self.present(navVC, animated: true, completion: nil)
    }
    
    
    @IBAction func shapeAction(_ sender: Any) {
        let vc = ShapeCropViewController(fullImage: contentImg)
        let navVC = UINavigationController(rootViewController: vc)
        navVC.isNavigationBarHidden = true
        navVC.modalPresentationStyle = .fullScreen
        self.present(navVC, animated: true, completion: nil)
    }
    
}
