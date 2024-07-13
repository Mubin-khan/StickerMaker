//
//  ImageEditViewController.swift
//  StickerApp
//
//  Created by Mubin Khan on 6/30/24.
//

import UIKit

class ImageEditViewController: UIViewController {
    
    @IBOutlet weak var stickerContainerView: UIView!
    @IBOutlet weak var emojiContainerview: UIView!
    @IBOutlet weak var emojiCollectionView: UICollectionView!
    @IBOutlet weak var filterView: UIView!
    @IBOutlet weak var filterCollectionView: UICollectionView!
    @IBOutlet weak var colorView: UIView!
    var thickness : CGFloat = 10
    var selectedBorderColor : UIColor = .white
    @IBOutlet weak var colorCollectionView: UICollectionView!
    @IBOutlet weak var fetureCollectionView: UICollectionView!
    var borderedImage : UIImage?
    
    enum feature : String, CaseIterable {
        case border = "Border"
        case emoji = "Emoji"
        case text = "Text"
        case filter = "Filter"
    }
    var emojis : [String] = [
        "emoji1",
        "emoji2",
        "emoji3",
        "emoji4",
        "emoji5"
    ]

    @IBOutlet weak var sampleImageView: UIImageView!
    var selectedFilter : SMFilter = SMFilter.ciFilters[0]
    let image : UIImage
    
    // stikcer
    private var _selectedStickerView:StickerViewMain?
    var selectedStickerView:StickerViewMain? {
        get {
            return _selectedStickerView
        }
        set {
            // if other sticker choosed then resign the handler
            if _selectedStickerView != newValue {
                if let selectedStickerView = _selectedStickerView {
                    selectedStickerView.showEditingHandlers = false
                }
                
                _selectedStickerView = newValue
            }
            // assign handler to new sticker added
            if let selectedStickerView = _selectedStickerView {
                selectedStickerView.showEditingHandlers = true
                selectedStickerView.superview?.bringSubviewToFront(selectedStickerView)
            }
        }
    }
    
    init(image : UIImage){
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sampleImageView.image = image
        setupCollectionView()
        
        navigationController?.isNavigationBarHidden = true
        applycifilter()
        showBorderView()
    }
    
    func setupCollectionView(){
        let nib = UINib(nibName: BrushCollectionViewCell.brushIdentifier, bundle: nil)
        fetureCollectionView.register(nib, forCellWithReuseIdentifier: BrushCollectionViewCell.brushIdentifier)
        fetureCollectionView.delegate = self
        fetureCollectionView.dataSource = self
        
        let nib1 = UINib(nibName: ColorCollectionViewCell.colorsIdentifier, bundle: nil)
        colorCollectionView.register(nib1, forCellWithReuseIdentifier: ColorCollectionViewCell.colorsIdentifier)
        colorCollectionView.delegate = self
        colorCollectionView.dataSource = self
        
        let nib2 = UINib(nibName: FontsCollectionViewCell.fontsIdentifier, bundle: nil)
        filterCollectionView.register(nib2, forCellWithReuseIdentifier: FontsCollectionViewCell.fontsIdentifier)
        filterCollectionView.delegate = self
        filterCollectionView.dataSource = self
        
        let nib3 = UINib(nibName: EmojiCollectionViewCell.emojiIdentifier, bundle: nil)
        emojiCollectionView.register(nib3, forCellWithReuseIdentifier: EmojiCollectionViewCell.emojiIdentifier)
        emojiCollectionView.delegate = self
        emojiCollectionView.dataSource = self
    }
    
    var lastPoint : Float = .zero
    @IBAction func sliderAction(_ sender: UISlider, forEvent event: UIEvent) {
        DispatchQueue.main.async { [self] in
            if round(sender.value) != lastPoint {
                thickness = CGFloat(round(sender.value))
                lastPoint = round(sender.value)
                applycifilter()
            }
        }
    }
    
    @IBAction func DoneAction(_ sender: Any) {
        let img = stickerContainerView.toImage()
        let imgname = UUID().uuidString
        let savedUrl = ImageSaveRetrieveManager.shared.saveImageToDocumentsFolder(image: img, imageName: imgname, foldername: ImageSaveRetrieveManager.imageStickersUrlFoldername)
        let vc = StickersViewController()
        vc.imgUrl = savedUrl
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func backAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
}

extension ImageEditViewController : UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == fetureCollectionView {
            return feature.allCases.count
        }
        if collectionView == colorCollectionView {
            return availableColors.count
        }
        if collectionView == filterCollectionView {
            return SMFilter.ciFilters.count
        }
        if collectionView == emojiCollectionView {
            return emojis.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == fetureCollectionView {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BrushCollectionViewCell.brushIdentifier, for: indexPath) as? BrushCollectionViewCell {
                cell.setup(to: feature.allCases[indexPath.row].rawValue)
                return cell
            }
        }else if collectionView == colorCollectionView {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ColorCollectionViewCell.colorsIdentifier, for: indexPath) as? ColorCollectionViewCell {
                cell.myContainer.backgroundColor = availableColors[indexPath.row]
                
                return cell
            }
        }else if collectionView == filterCollectionView {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FontsCollectionViewCell.fontsIdentifier, for: indexPath) as? FontsCollectionViewCell {
                cell.setUp(str: SMFilter.ciFilters[indexPath.row].name)
                return cell
            }
        }else if collectionView == emojiCollectionView {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EmojiCollectionViewCell.emojiIdentifier, for: indexPath) as? EmojiCollectionViewCell {
                cell.emojiImageView.image = UIImage(named: emojis[indexPath.row])
                return cell
            }
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == colorCollectionView {
            return CGSize(width: 30, height: 30)
        }else if collectionView == emojiCollectionView {
            return CGSize(width: 60, height: 60)
        }
        return CGSize(width: 80, height: collectionView.bounds.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        20
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        20
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if collectionView == fetureCollectionView {
            return UIEdgeInsets(top: 0, left: 20, bottom: 30, right: 20)
        }
        return UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == colorCollectionView {
            let color = availableColors[indexPath.row]
            selectedBorderColor = color
            applycifilter()
            filterView.isHidden = true
        }else if collectionView == filterCollectionView {
            selectedFilter = SMFilter.ciFilters[indexPath.row]
            applycifilter()
            filterView.isHidden = false
        }else if collectionView == fetureCollectionView {
            switch feature.allCases[indexPath.row] {
            case .border :
               showBorderView()
            case .filter :
               showFilterView()
            case .emoji :
               showEmojiView()
            default : break
            }
        }else if collectionView == emojiCollectionView {
            addFinalSticker(stickerName: emojis[indexPath.row])
        }
    }
    
    func showBorderView(){
        emojiContainerview.isHidden = true
        filterView.isHidden = true
        colorView.isHidden = false
    }
    
    func showFilterView(){
        emojiContainerview.isHidden = true
        filterView.isHidden = false
        colorView.isHidden = true
    }
    
    func showEmojiView(){
        emojiContainerview.isHidden = false
        filterView.isHidden = true
        colorView.isHidden = true
    }
    
    func addFinalSticker(stickerName : String) {
        let stickerWidth : CGFloat = 80
        let ww = stickerContainerView.bounds.width - stickerWidth / 2
        let hh = stickerContainerView.bounds.height - stickerWidth / 2
        let testImageView = UIImageView.init(frame: CGRect.init(x : 0, y : 0, width: stickerWidth, height: stickerWidth))
        testImageView.image = UIImage(named: stickerName)
        testImageView.contentMode = .scaleAspectFit
        let stickerView3 = StickerViewMain.init(contentView: testImageView)
        stickerView3.center = CGPoint(x: CGFloat.random(in: stickerWidth/2..<ww) , y: CGFloat.random(in: stickerWidth/2..<hh))
        stickerView3.delegate = self
        stickerView3.setImage(UIImage.init(named: "cancelStk")!, forHandler: StickerViewHandler.close)
        stickerView3.setImage(UIImage.init(named: "resizeStk")!, forHandler: StickerViewHandler.rotate)
        stickerView3.setImage(UIImage.init(named: "flipStk")!, forHandler: StickerViewHandler.flip)
        stickerView3.showEditingHandlers = false
        stickerView3.isUserInteractionEnabled = true
        self.stickerContainerView.addSubview(stickerView3)
        self.selectedStickerView = stickerView3
    }
    
    
    func applyBorderToImage(image : UIImage, color : UIColor){
        sampleImageView.image = image.stroked(with: color, thickness: thickness, quality: 10)
    }
    
    func applycifilter(){
        let img = selectedFilter.applier?(image) ?? image
        if thickness != 0 {
            applyBorderToImage(image: img, color: selectedBorderColor)
        }else {
            sampleImageView.image = img
        }
    }
}


extension ImageEditViewController : StickerViewDelegate {
    func stickerViewDidFlipped() {
        
    }
    
    func stickerSliderHideShow(flag: Bool) {
        
    }
    
    func stickerViewDidBeginMoving(_ stickerView: StickerViewMain) {
        self.selectedStickerView = stickerView
    }
    
    func stickerViewDidChangeMoving(_ stickerView: StickerViewMain) {
        
    }
    
    func stickerViewDidEndMoving(_ stickerView: StickerViewMain) {
    
    }
    
    func stickerViewDidBeginRotating(_ stickerView: StickerViewMain) {
        
    }
    
    func stickerViewDidChangeRotating(_ stickerView: StickerViewMain) {
        
    }
    
    func stickerViewDidEndRotating(_ stickerView: StickerViewMain) {
        setPanRoateOfStickerForUndoRedo(stickerView)
    }
    
    func setPanRoateOfStickerForUndoRedo(_ stickerView: StickerViewMain){
      
    }
    
    func stickerViewDidClose(_ stickerView: StickerViewMain) {
    }
    
    func stickerViewDidTap(_ stickerView: StickerViewMain) {
        self.selectedStickerView = stickerView
    }
}
