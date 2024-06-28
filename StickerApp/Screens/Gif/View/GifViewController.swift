//
//  GifViewController.swift
//  StickerApp
//
//  Created by Mubin Khan on 6/26/24.
//

import UIKit
import Kingfisher

class GifViewController: UIViewController {

    @IBOutlet weak var loaderView: UIView!
    @IBOutlet weak var gifCollectionView: UICollectionView!
    var searchAdaptor : SearchAdaptor? = nil
    let query = Query()
    let trendings = Trendings()
    let modelStore = ModelStore()
    var searchController: UISearchController!
    var dataChangedObserverToken: NSKeyValueObservation!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideLoaderView()
       
        setupNavigation()
        callTrending()
        
        dataChangedObserverToken = modelStore.observe(\ModelStore.updated) { (object, change) in
            
            DispatchQueue.main.async {
                self.gifCollectionView.reloadData()
            }
        }
        
        setupCollectionView()
    }
    
    private func setupNavigation(){
        self.navigationController?.isNavigationBarHidden = false
        searchController = UISearchController(searchResultsController: nil)
        
        self.title = "Get a Gif"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.largeTitleDisplayMode = .never
        searchController.searchBar.placeholder = "Search Tenor Gif"
        let backButton = UIBarButtonItem()
        backButton.title = "Back"
        backButton.tintColor = .white
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
        
        searchAdaptor = SearchAdaptor(searchView: searchController.searchBar, parentView: view) {
            self.performQuery(query: self.searchController.searchBar.text ?? "")
        }
        
        searchAdaptor?.cancelButtonClicked = { [weak self] (value) in
            if value {
                DispatchQueue.main.async {
                    self?.gifCollectionView.reloadData()
                }
            }
        }
    }
    
    private func setupCollectionView(){
        let nib = UINib(nibName: GifCollectionViewCell.gifcellIdentifier, bundle: nil)
        gifCollectionView.register(nib, forCellWithReuseIdentifier: GifCollectionViewCell.gifcellIdentifier)
        gifCollectionView.delegate = self
        gifCollectionView.dataSource = self
    }
    
    fileprivate func process(_ data: (Data)) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.processInBackground(data)
        }
    }
    
    func performQuery(query: String) {
        return self.query.query(query: query, limit:50).send { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self.process(data)
                case .error(let error):
                    self.displayError(error)
                }
            }
        }
    }
    
    func callTrending() {
        return self.trendings.query(limit:50).send { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self.process(data)
                case .error(let error):
                    self.displayError(error)
                }
            }
        }
    }
    
    fileprivate func processInBackground(_ data: (Data)) {
        let result = modelStore.process(data)
        DispatchQueue.main.async {
            switch result {
            case .success(let data):
                guard data.results.count >= 1 else {
                    return
                }
            case .error(let error):
                self.displayError(error)
            }
        }
    }
    
    fileprivate func displayError(_ error: (Error)) {
//        let alert = UIAlertController(title: "NetworkError", message: "error \(error)", preferredStyle: .actionSheet)
//        let okAction = UIAlertAction(title: "OK", style: .default, handler: { (action) in
//            alert.dismiss(animated: true, completion: {})
//        })
//        alert.addAction(okAction)
//        alert.popoverPresentationController?.sourceView = searchController.searchBar
//        self.present(alert, animated: true, completion: {})
    }


}


extension GifViewController : UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let txt = searchController.searchBar.text, txt.isEmpty {
            if modelStore.results.count > 0 {
                return modelStore.results[0].results.count
            }
        }else {
            if modelStore.results.count > 1 {
                return modelStore.results[1].results.count
            }
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GifCollectionViewCell.gifcellIdentifier, for: indexPath) as? GifCollectionViewCell {
            var url : URL?
            if let txt = searchController.searchBar.text, txt.isEmpty {
                if modelStore.results.count > 0 {
                    url = modelStore.results[0].results[indexPath.row].media[0].nanogif.url
                }
            }else {
                if modelStore.results.count > 1 {
                    url = modelStore.results[1].results[indexPath.row].media[0].nanogif.url
                }
            }
            if let url = url {
                cell.setup(url: url)
            }

            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: (collectionView.bounds.width - 12) / CGFloat(2) , height: (collectionView.bounds.width - 12) / CGFloat(2))
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        12
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        12
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // show loader 
        loaderView.isHidden = false
        var url : URL?
        if let txt = searchController.searchBar.text, txt.isEmpty {
            if modelStore.results.count > 0 {
                url = modelStore.results[0].results[indexPath.row].media[0].nanogif.url
            }
        }else {
            if modelStore.results.count > 1 {
                url = modelStore.results[1].results[indexPath.row].media[0].nanogif.url
            }
        }
        if let url = url {
            extractallframesfromgif(url: url)
        }
    }
    
    func extractallframesfromgif(url : URL){
        KingfisherManager.shared.retrieveImage(with: url) { result in
            switch result {
            case .success(let value):
                if let gifData = value.image.kf.gifRepresentation() {
                    if let frames = self.extractFramesFromGifData(gifData) {
                        DispatchQueue.main.async {
                            let vc = EditViewController(frames: frames)
                            self.navigationController?.pushViewController(vc, animated: true)
                        }
                    }
                } else {
                    self.hideLoaderView()
                    print("Failed to get GIF representation")
                }
            case .failure(let error):
                self.hideLoaderView()
            }
        }

    }
    
    func hideLoaderView(){
        DispatchQueue.main.async {
            self.loaderView.isHidden = true
        }
    }
    
    func extractFramesFromGifData(_ gifData: Data) -> [UIImage]? {
        guard let source = CGImageSourceCreateWithData(gifData as CFData, nil) else {
            self.hideLoaderView()
            return nil
        }

        let frameCount = CGImageSourceGetCount(source)
        var images = [UIImage]()

        for i in 0..<frameCount {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                let image = UIImage(cgImage: cgImage)
                images.append(image)
            }
        }

        return images
    }

}
