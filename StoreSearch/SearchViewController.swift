//
//  SearchViewController.swift
//  StoreSearch
//
//  Created by Buck Rozelle on 5/1/20.
//  Copyright © 2020 buckrozelledotcomLLC. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    @IBAction func segmentedChange(_ sender: UISegmentedControl) {
        //print("Segment Changed: \(sender.selectedSegmentIndex)")
        performSearch()
    }
    
    var searchResults = [SearchResult]()
    var hasSearched = false
    var isLoading = false
    var dataTask: URLSessionDataTask?
    var landscapeVC: LandscapeViewController?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.becomeFirstResponder()

        //Moves the search bar to clear the status bar 20 + 44.
        tableView.contentInset = UIEdgeInsets(top: 108,
                                              left: 0,
                                              bottom: 0,
                                              right: 0)
        
        var cellNib = UINib(nibName: TableView.CellIdentifiers.searchResultCell,
                            bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableView.CellIdentifiers.searchResultCell)
        
        cellNib = UINib(nibName: TableView.CellIdentifiers.nothingFoundCell,
                        bundle: nil)
        tableView.register(cellNib,
                           forCellReuseIdentifier: TableView.CellIdentifiers.nothingFoundCell)
        
        cellNib = UINib(nibName: TableView.CellIdentifiers.loadingCell,
                        bundle: nil)
        
        tableView.register(cellNib,
                           forCellReuseIdentifier: TableView.CellIdentifiers.loadingCell)
    }
    
    struct TableView {
        struct CellIdentifiers {
            static let searchResultCell = "SearchResultCell"
            static let nothingFoundCell = "NothingFoundCell"
            static let loadingCell = "LoadingCell"
        }
    }
    
    //MARK:- Helper Methods
    func iTunesURL(searchText: String, category: Int) -> URL {
        let kind: String
        switch category {
        case 1: kind = "musicTrack"
        case 2: kind = "software"
        case 3: kind = "ebook"
        default: kind = ""
        }
        
        let encodedText = searchText.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        let urlString = "https://itunes.apple.com/search?term=\(encodedText)&limit=200&entity=\(kind)"
        let url = URL(string: urlString)
        return url!
    }
    
    func parse(data: Data) -> [SearchResult] {
        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(ResultArray.self, from: data)
            return result.results
        } catch {
            print("JSON Error: \(error)")
            return []
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        performSearch()
    }
    
    //Error Handling
    func showNetworkError() {
        let alert = UIAlertController(title: "Whoops...",
                                      message: "There was an error accessing the iTunes Store." + "Please try again.",
                                      preferredStyle: .alert)
        
        let action = UIAlertAction(title: "OK",
                                   style: .default,
                                   handler: nil)
            
            alert.addAction(action)
        present(alert, animated: true,
                completion: nil)
        
    }
    
    override func willTransition(to newCollection: UITraitCollection,
                                 with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        
        //detect rotation
        switch newCollection.verticalSizeClass {
        case .compact:
            showLandscape(with: coordinator)
        case .regular, .unspecified: hideLandscape(with: coordinator)
        }
    }
    
    func showLandscape(with coordinator: UIViewControllerTransitionCoordinator) {
        
        // if you are already looking at landscape, then return right away.
        guard landscapeVC == nil else { return }
        
        // find the LandscapeViewController ID and instantiate it manually.
        landscapeVC = storyboard!.instantiateViewController(withIdentifier: "LandscapeViewController") as? LandscapeViewController
        if let controller = landscapeVC {
            
            //passing the search results to the landscapeVC
            controller.searchResults = searchResults
            
             //sets the size and postion of the new view controller.
            controller.view.frame = view.bounds
            //animation
            controller.view.alpha = 0
            
            // required to add the contents of one VC to an other.
            view.addSubview(controller.view)
            addChild(controller)
            //animation from transparent to fade in.
            coordinator.animate(alongsideTransition: { _ in controller.view.alpha = 1
                self.searchBar.resignFirstResponder()
                }, completion: { _ in controller.didMove(toParent: self)
                    //makes the detail screen go away if it is open when rotating.
                    if self.presentedViewController != nil {
                        self.dismiss(animated: true, completion: nil)
                    }
            })
        }
    }
    
    //Back to portrait view.
    func hideLandscape(with coordinator: UIViewControllerTransitionCoordinator) {
        if let controller = landscapeVC {
            controller.willMove(toParent: nil)
            
            //animation back from landscape
            coordinator.animate(alongsideTransition: { _ in
                controller.view.alpha = 0
            }, completion: { _ in
                controller.view.removeFromSuperview()
                controller.removeFromParent()
                self.landscapeVC = nil
            })
        }
    }
    
    
    
    //MARK:- Navigation
    //Finds the SearchResult object and passes it to DetailViewController
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowDetail" {
            let detailViewController = segue.destination as! DetailViewController
            let indexPath = sender as! IndexPath
            let searchResult = searchResults[indexPath.row]
            detailViewController.searchResult = searchResult
        }
    }
}

//Search Bar Delegate
extension SearchViewController: UISearchBarDelegate {
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
    
    func performSearch() {
        
        searchBar.resignFirstResponder()
        
        isLoading = true
        dataTask?.cancel()
        
        tableView.reloadData()
        
        hasSearched = true
        searchResults = []
        
        // Create URL object
        let url = iTunesURL(searchText: searchBar.text!,
                            category: segmentedControl.selectedSegmentIndex)
        
        // Get a shared URLSession instance
        let session = URLSession.shared
        
        // Create a data task.
        dataTask = session.dataTask(with: url,
                                    completionHandler: {
            data, response, error in
        
            if let error = error as NSError?, error.code == -999 {
                print("Failure! \(error.localizedDescription)")
                return //Search was cancelled
            } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                if let data = data {
                    self.searchResults = self.parse(data: data)
                    self.searchResults.sort(by: <)
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.tableView.reloadData()
                    }
                    return
                }
            } else {
                print("Failure! \(response!)")
            }
            
            DispatchQueue.main.async {
                self.hasSearched = false
                self.isLoading = false
                self.tableView.reloadData()
                self.showNetworkError()
            }
        })
        //Start the data task.
        dataTask?.resume()
    }
}

//MARK:- TableView delegate stuff
extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        if isLoading {
            return 1
        } else    if !hasSearched {
            return 0
        } else if searchResults.count == 0 {
            return 1
        } else {
            return searchResults.count
        }
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if isLoading {
            let cell = tableView.dequeueReusableCell(withIdentifier: TableView.CellIdentifiers.loadingCell,
                                                     for: indexPath)
            
            let spinner = cell.viewWithTag(100) as! UIActivityIndicatorView
            spinner.startAnimating()
            return cell
            
        } else if searchResults.count == 0 {
            return tableView.dequeueReusableCell(withIdentifier: TableView.CellIdentifiers.nothingFoundCell,
                                                 for: indexPath)
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: TableView.CellIdentifiers.searchResultCell,
                                                     for: indexPath) as! SearchResultCell
            
            let searchResult = searchResults[indexPath.row]
            cell.configure(for: searchResult)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath,
                              animated: true)
        performSegue(withIdentifier: "ShowDetail",
                     sender: indexPath)
    }
    
    func tableView(_ tableView: UITableView,
                   willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if searchResults.count == 0 || isLoading {
            return nil
        } else {
            return indexPath
        }
    }
}

