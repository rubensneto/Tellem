//
//  ContactInfoViewController.swift
//  TellemApp
//
//  Created by Rubens Neto on 16/03/17.
//  Copyright © 2017 Rubens Neto. All rights reserved.
//

import UIKit
import CoreData
import SCLAlertView
import FirebaseDatabase

class ContactInfoViewController: UIViewController {
    
    var tellemUser: TellemUser?

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var contactNameLabel: UILabel!
    @IBOutlet weak var contactProfessionLabel: UILabel!
    @IBOutlet weak var businessDescriptionLabel: UILabel!
    @IBOutlet weak var contactCityLabel: UILabel!
    @IBOutlet weak var blockUserButton: UIButton!
    
    lazy var fetchedResultsController: NSFetchedResultsController<TellemUser> = {
        let fetchRequest = NSFetchRequest<TellemUser>(entityName: "TellemUser")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lastMessage.date", ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "lastMessage != nil")
        let appDell = UIApplication.shared.delegate as! AppDelegate
        let context = appDell.persistentContainer.viewContext
        let frc = NSFetchedResultsController<TellemUser>(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        return frc
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Contact Info"
        navigationItem.backBarButtonItem?.title = "Chat"
        profileImageView.clipsToBounds = true
        
        self.tabBarController?.tabBar.isHidden = true
        
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
        
        if let photoURL = tellemUser?.photoURL {
            profileImageView.loadImageUsingCacheWith(urlString: photoURL)
        } else {
            profileImageView.image = UIImage(named: "avatarImage")
        }
        
        if let name = tellemUser?.name {
            contactNameLabel.text = name
        }
        
        let tellemUserRef = FIRDatabase.database().reference().child("users").child(tellemUser!.id!)
        tellemUserRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.value is NSNull {
                self.contactProfessionLabel.text = "This account is no longer active"
                return
            }
            let tellemUserDictionary = snapshot.value as! [String : AnyObject]
            self.contactProfessionLabel.text = tellemUserDictionary["businessField"] as? String ?? ""
            self.businessDescriptionLabel.text = tellemUserDictionary["businessDescription"] as? String ?? ""
            let tellemUserLatitude = tellemUserDictionary["latitude"] as? Double
            let tellemUserLongitude = tellemUserDictionary["longitude"] as? Double
            let userLatitude = UserDefaults().value(forKey: "userLatitude") as? Double
            let userLongitude = UserDefaults().value(forKey: "userLongitude") as? Double
            if let distance = SearchViewController.findDistance(professionalLatitude: tellemUserLatitude!, professionalLongitude: tellemUserLongitude!, userLatitude: userLatitude!, userLongitude: userLongitude!) {
                self.contactCityLabel.text = SearchViewController.format(distance: distance)
            }
            
        }) { (error) in
            print(error)
        }
        
        
        if tellemUser?.isBlocked == true {
            blockUserButton.setTitle("Unblock this Contact", for: .normal)
        } else {
            blockUserButton.setTitle("Block this Contact", for: .normal)
        }
        
    }
    
    @IBAction func clearChat(_ sender: UIButton) {
        let alertSheet = UIAlertController(title: "Confirm Delete", message: "All messages from this contact will be deleted permanently!", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (action) in
            
            let appDell = UIApplication.shared.delegate as! AppDelegate
            let context = appDell.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<Message>(entityName: "Message")
            fetchRequest.includesPropertyValues = false
            
            do {
                let messages = try context.fetch(fetchRequest)
                
                for message in messages {
                    if message.senderId == self.tellemUser?.id || message.user == self.tellemUser {
                        context.delete(message)
                    }
                }
                try context.save()
            } catch let error{
                print(error)
            }
            self.tabBarController?.tabBar.isHidden = false
            self.navigationController!.popToRootViewController(animated: true)
        }
        
        alertSheet.addAction(cancelAction)
        alertSheet.addAction(deleteAction)
        
        self.present(alertSheet, animated: true)
    }
    
    @IBAction func blockThisContact(_ sender: UIButton) {
        if tellemUser?.isBlocked == false {
            blockUserButton.setTitle("Unblock this Contact", for: .normal)
            tellemUser?.isBlocked = true
        } else {
            blockUserButton.setTitle("Block this Contact", for: .normal)
            tellemUser?.isBlocked = false
        }
    }
}
