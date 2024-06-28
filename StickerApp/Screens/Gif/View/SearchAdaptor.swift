//
//  SearchAdaptor.swift
//
//  Created by Paul Ossenbruggen on 6/20/17.
//  Copyright © 2017 Paul Ossenbruggen. All rights reserved.
//

import UIKit


class SearchAdaptor : NSObject {
    var completion : (() -> Void)? = nil
    var cancelButtonClicked : ((Bool) -> Void)?
    
    convenience init(searchView: UISearchBar,
                     parentView: UIView,
                     completion: @escaping () -> Void ) {
        self.init()
        
        self.completion = completion
        searchView.delegate = self
    }
    
    func queryChanged(searchBar: UISearchBar, searchText: String) {
        DispatchQueue.main.async {
            searchBar.text = searchText
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: DispatchTime.now() + .milliseconds(500)) {
                DispatchQueue.main.async {
                    self.completion?()
                }
            }
        }
    }
}

extension SearchAdaptor : UISearchBarDelegate {
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        DispatchQueue.main.async {
            searchBar.resignFirstResponder()
        }
        self.completion?()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.queryChanged(searchBar: searchBar, searchText: searchText)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.cancelButtonClicked?(true)
    }
}


