//
//  EditViewController.swift
//  StickerApp
//
//  Created by Mubin Khan on 6/18/24.
//

import UIKit

class EditViewController: UIViewController {

    @IBOutlet weak var contentImageView: UIImageView!
    @IBOutlet weak var contentImageHeightCon: NSLayoutConstraint!
    @IBOutlet weak var contentImageWidthCon: NSLayoutConstraint!
    @IBOutlet weak var container: UIView!
    
    lazy var displayLink: CADisplayLink = CADisplayLink(target: self,
                                                      selector: #selector(displayLinkFired(link:)))
    
    var frames : [UIImage] = []
    var currentFrameNumber : Int = 0
    
    init(frames : [UIImage]) {
        self.frames = frames
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.isNavigationBarHidden = true
        
        self.displayLink.add(to: .main, forMode: .common)
        self.displayLink.preferredFramesPerSecond = 30
 
        let availableWidth = view.bounds.width - 50
        let sz = frames[0].size.calculateFinalSize(in: CGSize(width: availableWidth, height: availableWidth))
        contentImageWidthCon.constant = sz.width
        contentImageHeightCon.constant = sz.height
    }

    @objc func displayLinkFired(link: CADisplayLink) {
        contentImageView.image = frames[currentFrameNumber]
        currentFrameNumber += 1;
        if currentFrameNumber >= frames.count {
            currentFrameNumber = 0
        }
    }
    
    @IBAction func backAction(_ sender: Any) {
        displayLink.invalidate()
        navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func strokeWidthChangeAction(_ sender: UISlider, forEvent event: UIEvent) {
        contentImageView.layer.borderWidth = CGFloat(sender.value * 20)
    }
    
    @IBAction func speedChangeAction(_ sender: UISlider, forEvent event: UIEvent) {
        self.displayLink.preferredFramesPerSecond = Int(sender.value * 30) + 1
    }
    
}
