//
//  SearchViewController.swift
//  TellemApp
//
//  Created by Rubens Neto on 06/03/17.
//  Copyright © 2017 Rubens Neto. All rights reserved.
//

import UIKit
import Firebase
import SCLAlertView
import CoreData
import GooglePlaces
import MapKit

class SearchViewController: UITableViewController, UISearchResultsUpdating, CLLocationManagerDelegate {
    
    let activityIndicator = ActivityIndicatorController()
    @IBOutlet var searchTableView: UITableView!
    
    let searchController = UISearchController(searchResultsController: nil)
    var professionals = [CompanyObject]()
    var filteredProfessionals = [CompanyObject]()
    var databaseRef = FIRDatabase.database().reference()
    let locationManager = CLLocationManager()
    let userLatitude = UserDefaults().value(forKey: "userLatitude") as! NSNumber
    let userLongitude = UserDefaults().value(forKey: "userLongitude") as! NSNumber
    override func viewDidLoad() {
    
        super.viewDidLoad()
        tabBarItem.isEnabled = true
        tabBarController?.tabBar.isHidden = false
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        queryProfessionals()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text! != "" {
            return filteredProfessionals.count
        }
        return 0
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "resultCell", for: indexPath)
        
        let imageView = cell.viewWithTag(1) as! UIImageView
        let nameLabel = cell.viewWithTag(2) as! UILabel
        let professionLabel = cell.viewWithTag(3) as! UILabel
        let distanceLabel = cell.viewWithTag(4) as! UILabel
        
        imageView.layer.cornerRadius = imageView.frame.width / 2

        if searchController.isActive && searchController.searchBar.text! != "" {
            let professional = filteredProfessionals[indexPath.row]
            nameLabel.text = professional.name
            professionLabel.text = professional.businessField
            if let photoURL = professional.photoURL {
                imageView.loadImageUsingCacheWith(urlString: photoURL)
            }
            distanceLabel.text = SearchViewController.format(distance: professional.distance)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let appDell = UIApplication.shared.delegate as! AppDelegate
        let context = appDell.persistentContainer.viewContext
        
        let tellemUser = NSEntityDescription.insertNewObject(forEntityName: "TellemUser", into: context) as! TellemUser
        tellemUser.name = filteredProfessionals[indexPath.row].name
        tellemUser.id = filteredProfessionals[indexPath.row].uid
        tellemUser.photoURL = filteredProfessionals[indexPath.row].photoURL
        tellemUser.business = filteredProfessionals[indexPath.row].businessField
        tellemUser.businessDescription = filteredProfessionals[indexPath.row].businessDescription
        
        appDell.saveContext()
        
        let conversationViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "conversationViewController") as! ConversationViewController
        conversationViewController.senderId = UserDefaults().value(forKey: "userId") as! String!
        conversationViewController.senderDisplayName = UserDefaults().value(forKey: "username") as! String!
        conversationViewController.tellemUser = tellemUser
        
        navigationController?.pushViewController(conversationViewController, animated: true)
    }
    
    func queryProfessionals(){
        activityIndicator.startActivityIndicator(view: view)
        databaseRef.child("users").observe(.childAdded, with: { (snapshot) in
            var dictionary = snapshot.value as! [String: AnyObject]
            let professional = CompanyObject()
            professional.name = dictionary["name"] as! String
            professional.businessField = dictionary["businessField"] as! String
            professional.latitude = dictionary["latitude"] as! NSNumber
            professional.longitude = dictionary["longitude"] as! NSNumber
            professional.uid = snapshot.key
            professional.photoURL = dictionary["photoURL"] as! String
            if professional.uid != UserDefaults().value(forKey: "userId") as? String {
                self.professionals.append(professional)
            }
            self.activityIndicator.stopActivityIndicator()
        }) { (error) in
            self.activityIndicator.stopActivityIndicator()
            SCLAlertView().showError("OOPS!", subTitle: "Looks like something went wrong in your your search!")
        }
    }

    func updateSearchResults(for searchController: UISearchController) {
        filteredContext(searchText: searchController.searchBar.text!)
    }
    
    func filteredContext(searchText: String) {
        var results = [CompanyObject]()
        for professional in self.professionals {
            if let business = professional.businessField,
                let name = professional.name, let id = professional.uid {
                if (business.lowercased().contains(searchText.lowercased())) ||
                    (name.lowercased().contains(searchText.lowercased())) &&
                    id != UserDefaults().value(forKey: "userId") as? String {
                    professional.distance = SearchViewController.findDistance(professionalLatitude: Double(professional.latitude), professionalLongitude: Double(professional.longitude), userLatitude: Double(self.userLatitude), userLongitude: Double(self.userLongitude))
                    results.append(professional)
                }
            }
        }
        filteredProfessionals = results
        filteredProfessionals.sort(by: {$0.distance < $1.distance})
        tableView.reloadData()
    }
    
    static func findDistance(professionalLatitude: Double, professionalLongitude: Double, userLatitude: Double, userLongitude: Double) -> Double? {
        let professionalLocation = CLLocation(latitude: professionalLatitude, longitude: professionalLongitude)
        let userLocation = CLLocation(latitude: userLatitude, longitude: userLongitude)
        let distance = userLocation.distance(from: professionalLocation)
        return distance
    }
    
    static func format(distance: CLLocationDistance) -> String {
        let formattedDistance = MKDistanceFormatter()
        formattedDistance.unitStyle = .abbreviated
        formattedDistance.units = .metric
        let distanceString = formattedDistance.string(fromDistance: distance)
        return distanceString
    }
}
