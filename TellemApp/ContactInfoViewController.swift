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
        
        if let photoURL = tellemUser?.photoURL {
            profileImageView.loadImageUsingCacheWith(urlString: photoURL)
            
        } else {
            profileImageView.image = UIImage(named: "avatarImage")
        }
        if let name = tellemUser?.name {
            contactNameLabel.text = name
        }
        contactProfessionLabel.text = tellemUser?.business ?? "Client"
        contactCityLabel.text = tellemUser?.city ?? ""
        businessDescriptionLabel.text = tellemUser?.businessDescription ?? ""
        
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
                    if message.senderId == self.tellemUser?.id || message.receiver == self.tellemUser {
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
