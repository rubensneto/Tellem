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
    var users = [[String: AnyObject]]()
    var filteredUsers = [NSDictionary?]()
    var databaseRef = FIRDatabase.database().reference()
    let locationManager = CLLocationManager()
    var userCurrentLocation: CLLocation?

    override func viewDidLoad() {
    
        super.viewDidLoad()
        tabBarItem.isEnabled = true
        tabBarController?.tabBar.isHidden = false
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        askForUserLocation()
        
        }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text! != "" {
            return filteredUsers.count
        }
        return 0
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        filteredContext(searchText: searchController.searchBar.text!)
    }
    
    func filteredContext(searchText: String) {
        var results = [NSDictionary?]()
        for user in users {
            if let business = user["businessField"] as? String,
                let name = user["name"] as? String , let id = user["key"] as? String {
                if (business.lowercased().contains(searchText.lowercased())) ||
                    (name.lowercased().contains(searchText.lowercased())) &&
                    id != FIRAuth.auth()?.currentUser?.uid{
                    results.append(user as NSDictionary?)
                }
            }
        }
        filteredUsers = results
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "resultCell", for: indexPath)
        
        let imageView = cell.viewWithTag(1) as! UIImageView
        let nameLabel = cell.viewWithTag(2) as! UILabel
        let professionLabel = cell.viewWithTag(3) as! UILabel
        let distanceLabel = cell.viewWithTag(4) as! UILabel
        
        imageView.layer.cornerRadius = imageView.frame.width / 2
    
        var user: NSDictionary?
        
        if searchController.isActive && searchController.searchBar.text! != "" {
            user = filteredUsers[indexPath.row]
            nameLabel.text = user?["name"] as? String
            professionLabel.text = user?["businessField"] as? String
            let profileImageURL = user?["photoURL"] as? String
            
            imageView.loadImageUsingCacheWith(urlString: profileImageURL!)
            
            if let tellemUserLocation = user?["tellemUserLocation"] as? CLLocation,
                let distance = userCurrentLocation?.distance(from: tellemUserLocation){
                let formattedDistance = MKDistanceFormatter()
                formattedDistance.unitStyle = .abbreviated
                let distanceString = formattedDistance.string(fromDistance: distance)
                distanceLabel.text = distanceString
            } else {
                distanceLabel.isHidden = true
            }
        }
        return cell
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        queryUsersNearby(location: userCurrentLocation)
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let appDell = UIApplication.shared.delegate as! AppDelegate
        let context = appDell.persistentContainer.viewContext
        
        let tellemUser = NSEntityDescription.insertNewObject(forEntityName: "TellemUser", into: context) as! TellemUser
        tellemUser.name = filteredUsers[indexPath.row]?["name"] as? String
        tellemUser.id = filteredUsers[indexPath.row]?["key"] as? String
        tellemUser.photoURL = filteredUsers[indexPath.row]?["photoURL"] as? String
        tellemUser.business = filteredUsers[indexPath.row]?["businessField"] as? String
        tellemUser.businessDescription = filteredUsers[indexPath.row]?["businessDescription"] as? String
        
        
        appDell.saveContext()
        
        let conversationViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "conversationViewController") as! ConversationViewController
        conversationViewController.senderId = FIRAuth.auth()?.currentUser?.uid
        conversationViewController.senderDisplayName = UserDefaults().value(forKey: "username") as! String!
        conversationViewController.tellemUser = tellemUser
        
        navigationController?.pushViewController(conversationViewController, animated: true)
    }
    
    func askForUserLocation(){
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.userCurrentLocation = locations.last
    }
    
    func queryUsersNearby(location: CLLocation?){
        activityIndicator.startActivityIndicator(view: view)
        databaseRef.child("users").observe(.childAdded, with: { (snapshot) in
            var dictionary = snapshot.value as! [String: AnyObject]
            print(dictionary)
            dictionary["key"] = snapshot.key as AnyObject?
            let userId = dictionary["key"] as? String
            if location != nil {
                let tellemUserLatitude = dictionary["latitude"] as! String
                let tellemUserLongitude = dictionary["longitude"] as! String
                let tellemUserLocation = CLLocation(latitude: Double(tellemUserLatitude)!, longitude: Double(tellemUserLongitude)!)
                dictionary["tellemUserLocation"] = tellemUserLocation as AnyObject
            }
            if userId != FIRAuth.auth()?.currentUser?.uid {
                self.users.append(dictionary)
            }
            self.activityIndicator.stopActivityIndicator()
            
        }) { (error) in
            self.activityIndicator.stopActivityIndicator()
            SCLAlertView().showError("OOPS!", subTitle: "Looks like something went wrong in your your search!")
        }
    }
}
