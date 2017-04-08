//
//  ChatsViewController.swift
//  Tellem
//
//  Created by Rubens Neto on 09/02/17.
//  Copyright © 2017 Rubens Neto. All rights reserved.
//

import UIKit
import Firebase
import CoreData
import JSQSystemSoundPlayer

class ChatsViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate {

    let currentUserId = FIRAuth.auth()?.currentUser?.uid
    
    override func viewDidLoad() {
        tabBarItem.isEnabled = true
        tabBarController?.tabBar.isHidden = false
        collectionView?.alwaysBounceVertical = true
        navigationItem.title = "Chats"
        do {
            try fetchedResultsController.performFetch()
            observeNewMessage()
        } catch let error {
            print(error)
        }
        collectionView?.allowsMultipleSelection = true
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController<TellemUser> = {
        let fetchRequest = NSFetchRequest<TellemUser>(entityName: "TellemUser")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lastMessage.date", ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "lastMessage != nil")
        let appDell = UIApplication.shared.delegate as! AppDelegate
        let context = appDell.persistentContainer.viewContext
        let frc = NSFetchedResultsController<TellemUser>(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        return frc
    }()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        collectionView?.reloadData()
    }
    
    var blockOperations = [BlockOperation]()
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if type == .insert {
            print("Did change an object", anObject)
            blockOperations.append(BlockOperation(block: {
                self.collectionView?.insertItems(at: [newIndexPath!])
            }))
        }
        if type == .delete {
            blockOperations.append(BlockOperation(block: {
                self.collectionView?.deleteItems(at: [indexPath!])
            }))
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView?.performBatchUpdates({
            for operation in self.blockOperations {
                operation.start()
            }
        }, completion: { (copletion) in
            self.collectionView?.reloadData()
        })
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let count = fetchedResultsController.sections?[0].numberOfObjects {
            return count
        }
        return 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let tellemUser = fetchedResultsController.object(at: indexPath)
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "chatCell", for: indexPath)
        let profileImageView = cell.viewWithTag(1) as! UIImageView
        let contactNameLabel = cell.viewWithTag(2) as! UILabel
        let messageLabel = cell.viewWithTag(3) as! UILabel
        let timeLabel = cell.viewWithTag(4) as! UILabel
        let businessLabel = cell.viewWithTag(5) as! UILabel
        let newMessagesLabel = cell.viewWithTag(6) as! UILabel
        
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
        
        if let photoURL = tellemUser.photoURL{
            profileImageView.loadImageUsingCacheWith(urlString: photoURL)
        }
        
        if let name = tellemUser.name {
            contactNameLabel.text = name
        }
        
        if let business = tellemUser.business {
            businessLabel.text = business
        }
        
        if let date = tellemUser.lastMessage?.date as? Date {
            let dateFormatter = DateFormatter()
            let daysAgo = date.daysBetweenDate(toDate: Date())
            switch daysAgo {
            case 0 :
                dateFormatter.dateFormat = "hh:mm"
                timeLabel.text = dateFormatter.string(from: date as Date)
            case 1 :
                timeLabel.text = "Yesterday"
            default:
                dateFormatter.dateFormat = "dd/MM/yyyy"
                timeLabel.text = dateFormatter.string(from: date as Date)
            }
            
        }
        
        if let text = tellemUser.lastMessage?.text {
            messageLabel.text = text
        }
        
        newMessagesLabel.layer.cornerRadius = newMessagesLabel.frame.width / 2
        
        var newMessages = 0
        if ((tellemUser.messages?.count) != nil) {
            newMessages = (tellemUser.messages?.count)! - Int(tellemUser.readMessages)
        }
        
        if tellemUser.lastMessage?.senderId == UserDefaults().value(forKey: "userId") as? String {
            newMessages = 0
        }
        
        if newMessages > 0 {
            newMessagesLabel.text = "\(newMessages)"
            newMessagesLabel.backgroundColor = UIColor.jsq_messageBubbleBlue()
        } else {
            newMessagesLabel.backgroundColor = UIColor.white
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let tellemUser = fetchedResultsController.object(at: indexPath)
        tellemUser.readMessages = Int16((tellemUser.messages?.count)!)
        
        let conversationViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "conversationViewController") as! ConversationViewController
        conversationViewController.senderId = FIRAuth.auth()?.currentUser?.uid
        conversationViewController.senderDisplayName = UserDefaults().value(forKey: "username") as! String
        conversationViewController.tellemUser = fetchedResultsController.object(at: indexPath)
        
        navigationController?.pushViewController(conversationViewController, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.view.frame.width, height: 76)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = UIColor.groupTableViewBackground
    }
    
    override func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = UIColor.white
    }
}
