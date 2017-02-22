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
        let appDell = UIApplication.shared.delegate as! AppDelegate
        let context = appDell.persistentContainer.viewContext
        
        let mark = TellemUser(context: context)
        mark.name = "Mark Zukerberg"
        mark.photoURL = "mark"
        
        let messageMark = Message(context: context)
        messageMark.date = NSDate()
        messageMark.user = mark
        messageMark.text = "How much for the app?"
        
        let steve = TellemUser(context: context)
        steve.name = "Steve Jobs"
        steve.photoURL = "steve"
        
        let messageSteve = Message()
        messageSteve.date = NSDate()
        messageSteve.user = steve
        messageSteve.text = "I cover any offer for this application!"
        
        //appDell.saveContext()
        
        messages = [messageSteve, messageMark]
    }
}
