//
//  ChatsHelper.swift
//  Tellem
//
//  Created by Rubens Neto on 20/02/17.
//  Copyright © 2017 Rubens Neto. All rights reserved.
//

import UIKit
import CoreData
import Firebase

extension ChatsViewController {
    
    func setData(){
        clearEntities("TellemUser")
        clearEntities("Message")
    }
    
    
    static func createMessage(to user: TellemUser, date: NSDate, text: String, context: NSManagedObjectContext, senderId: String) -> Message {
        let message = NSEntityDescription.insertNewObject(forEntityName: "Message", into: context) as! Message
        message.receiver = user
        message.date = date
        message.text = text
        message.senderId = senderId
        
        
        user.lastMessage = message
        
        return message
    }
    
    func observeNewMessage(){
        if let uid = FIRAuth.auth()?.currentUser?.uid {
            let receiverMessagesRef = FIRDatabase.database().reference().child("receiverMessages").child(uid)
            receiverMessagesRef.observe(.childAdded, with: { (snapshot) in
                let messageRef = FIRDatabase.database().reference().child("messages").child(snapshot.key)
                messageRef.observeSingleEvent(of: .value, with: { (snapshot) in
                    let appDel = UIApplication.shared.delegate as! AppDelegate
                    let context = appDel.persistentContainer.viewContext
                    self.receiveMessage(snapshot: snapshot, context: context, fetchedResultsController: self.fetchedResultsController, completion: { 
                        receiverMessagesRef.removeValue()
                        messageRef.removeValue()
                    })
                }, withCancel: nil)
            }, withCancel: nil)
        }
    }
    
   
        
    func receiveMessage(snapshot: FIRDataSnapshot, context: NSManagedObjectContext, fetchedResultsController: NSFetchedResultsController<TellemUser>, completion: @escaping ()->()){
        var dictionary = snapshot.value as! [String: AnyObject]
        let senderRef = FIRDatabase.database().reference().child("users").child(dictionary["senderId"] as! String)
        let timestamp = dictionary["timestamp"] as! Int
        let date = NSDate.init(timeIntervalSince1970: TimeInterval(timestamp))
        
        senderRef.observeSingleEvent(of: .value, with: { (snap) in
            let userDict = snap.value as! [String: AnyObject]
            if fetchedResultsController.fetchedObjects!.count > 0 {
                for user in fetchedResultsController.fetchedObjects! {
                    if user.id == snap.key {
                        if user.isBlocked == false {
                            ChatsViewController.createMessage(to: user, date: date, text: dictionary["text"] as! String, context: context, senderId: user.id!)
                        } else {
                            completion()
                        }
                    } else {
                        let tellemUser = self.createUser(id: snap.key, dictionary: userDict, context: context)
                        ChatsViewController.createMessage(to: tellemUser, date: date, text: dictionary["text"] as! String, context: context, senderId: tellemUser.id!)
                    }
                }
            } else {
                let tellemUser = self.createUser(id: snap.key, dictionary: userDict, context: context)
                ChatsViewController.createMessage(to: tellemUser, date: date, text: dictionary["text"] as! String, context: context, senderId: tellemUser.id!)
            }
            
            completion()
        }) { (error) in
            print(error)
        }
    }
    
    func createUser(id: String, dictionary: [String : AnyObject], context: NSManagedObjectContext) -> TellemUser {
        let tellemUser = NSEntityDescription.insertNewObject(forEntityName: "TellemUser", into: context) as! TellemUser
        tellemUser.id = id
        tellemUser.name = dictionary["name"] as? String
        tellemUser.business = dictionary["businessField"] as? String
        tellemUser.photoURL = dictionary["photoURL"] as? String
        
        return tellemUser
    }
    
    func clearEntities(_ name: String){
        let appDell = UIApplication.shared.delegate as! AppDelegate
        let context = appDell.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: name)
        fetchRequest.includesPropertyValues = false
        
        do {
            let items = try context.fetch(fetchRequest) as! [NSManagedObject]
            
            for item in items {
                 context.delete(item)
            }
            
            try context.save()
            
        } catch let error{
            print(error)
        }
    }
    
}
