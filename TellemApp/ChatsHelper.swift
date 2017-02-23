//
//  ChatsHelper.swift
//  Tellem
//
//  Created by Rubens Neto on 20/02/17.
//  Copyright © 2017 Rubens Neto. All rights reserved.
//

import UIKit
import CoreData

extension ChatsViewController {
    
    
    
    func setData(){
        
        clearEntities(name: "TellemUser")
        clearEntities(name: "Message")
        
        let appDell = UIApplication.shared.delegate as! AppDelegate
        let context = appDell.persistentContainer.viewContext
        
        let mark = NSEntityDescription.insertNewObject(forEntityName: "TellemUser", into: context) as! TellemUser
        mark.name = "Mark Zukerberg"
        mark.photoURL = "mark"
        mark.business = "Facebook CEO"
        
        let messageMark = NSEntityDescription.insertNewObject(forEntityName: "Message", into: context) as! Message
        messageMark.date = NSDate()
        messageMark.user = mark
        messageMark.text = "How much for the app?"
        
        let steve = NSEntityDescription.insertNewObject(forEntityName: "TellemUser", into: context) as! TellemUser
        steve.name = "Steve Jobs"
        steve.photoURL = "steve"
        steve.business = "Apple CEO"
        
        let messageSteve = NSEntityDescription.insertNewObject(forEntityName: "Message", into: context) as! Message
        messageSteve.date = NSDate().addingTimeInterval(-60)
        messageSteve.user = steve
        messageSteve.text = "I cover any offer for this application!"
        
        let bill = NSEntityDescription.insertNewObject(forEntityName: "TellemUser", into: context) as! TellemUser
        bill.name = "Bill Gates"
        bill.photoURL = "bill"
        bill.business = "Microsoft CEO"
        
        let messageBill = NSEntityDescription.insertNewObject(forEntityName: "Message", into: context) as! Message
        messageBill.date = NSDate().addingTimeInterval(-120)
        messageBill.user = bill
        messageBill.text = "Did you patent already?"
        
        let messageBill2 = NSEntityDescription.insertNewObject(forEntityName: "Message", into: context) as! Message
        messageBill2.date = NSDate().addingTimeInterval(-180)
        messageBill2.user = bill
        messageBill2.text = "Lets talk dude"
        
        appDell.saveContext()
        
        loadMessagesData()
    }
    
    func loadMessagesData(){
        let appDell = UIApplication.shared.delegate as! AppDelegate
        let context = appDell.persistentContainer.viewContext
        
        if let users = fetchUsers() {
            
            messages = [Message]()
            
            for user in users {
                
                let sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
                let request: NSFetchRequest<Message> = Message.fetchRequest()
                request.sortDescriptors = sortDescriptors
                request.predicate = NSPredicate(format: "user.name = %@", user.name!)
                request.fetchLimit = 1
                
                do {
                    
                    let fetchedMessages = try context.fetch(request) as [Message]
                    messages?.append(contentsOf: fetchedMessages)
                    
                } catch let error {
                    print(error)
                }
                
                messages?.sort(by: { $0.date?.compare($1.date as! Date) == .orderedDescending })
            }
        }
    }
    
    private func fetchUsers() -> [TellemUser]? {
        let appDell = UIApplication.shared.delegate as! AppDelegate
        let context = appDell.persistentContainer.viewContext
        
        let request: NSFetchRequest<TellemUser> = TellemUser.fetchRequest()
        
        do {
            return try context.fetch(request)
        } catch let error {
            print(error)
        }
        return nil
    }

    func clearEntities(name: String){
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
