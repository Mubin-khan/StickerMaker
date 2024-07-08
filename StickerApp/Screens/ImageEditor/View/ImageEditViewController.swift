//
//  ImageEditViewController.swift
//  StickerApp
//
//  Created by Mubin Khan on 6/30/24.
//

import UIKit

class ImageEditViewController: UIViewController {
    
    @IBOutlet weak var filterView: UIView!
    @IBOutlet weak var filterCollectionView: UICollectionView!
    @IBOutlet weak var colorView: UIView!
    var thickness : CGFloat = .zero
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

    @IBOutlet weak var sampleImageView: UIImageView!
    var selectedFilter : SMFilter = SMFilter.ciFilters[0]
    let image : UIImage
    
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
        
        navigationController?.isNavigationBarHidden = true
    }
    
    @IBAction func sliderAction(_ sender: UISlider, forEvent event: UIEvent) {
        DispatchQueue.main.async { [self] in
            var img : UIImage = image
            if sender.value != 0 {
                img = image.stroked(with: selectedBorderColor, thickness: CGFloat(round(sender.value)), quality: 5)
                borderedImage = img
            }else {
                borderedImage = nil
            }
            thickness = CGFloat(round(sender.value))
           applycifilter()
        }
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
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == colorCollectionView {
            return CGSize(width: 30, height: 30)
        }
        return CGSize(width: 80, height: collectionView.bounds.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        20
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        20
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == colorCollectionView {
            let color = availableColors[indexPath.row]
            applyBorderToImage(color: color)
            filterView.isHidden = true
        }else if collectionView == filterCollectionView {
            selectedFilter = SMFilter.ciFilters[indexPath.row]
            applycifilter()
            filterView.isHidden = false
        }else if collectionView == fetureCollectionView {
            switch feature.allCases[indexPath.row] {
                case .border : filterView.isHidden = true
            case .filter : filterView.isHidden = false
            default : break
            }
        }
    }
    
    
    func applyBorderToImage(color : UIColor){
        if thickness != 0 {
            let img = image.stroked(with: color, thickness: thickness, quality: 5)
            borderedImage = img
        }else {
            borderedImage = nil
        }
       
        applycifilter()
        selectedBorderColor = color
    }
    
    func applycifilter(){
        let img = borderedImage ?? image
        sampleImageView.image = selectedFilter.applier?(img) ?? img
    }
}
