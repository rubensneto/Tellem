//
//  ConversationViewController.swift
//  TellemApp
//
//  Created by Rubens Neto on 23/02/17.
//  Copyright © 2017 Rubens Neto. All rights reserved.
//
import CoreData
import UIKit
import JSQMessagesViewController
import Firebase

class ConversationViewController: JSQMessagesViewController, NSFetchedResultsControllerDelegate {
    
    var tellemUser: TellemUser?
    let currentUserId = FIRAuth.auth()?.currentUser?.uid
    
    var jsqMessages: [JSQMessage]?
    let bubbleFactory = JSQMessagesBubbleImageFactory()
    var outgoingBubbleImageView: JSQMessagesBubbleImage!
    var incomingBubbleImageView: JSQMessagesBubbleImage!

    lazy var fetchedResultsController: NSFetchedResultsController<Message> = {
        let fetchRequest = NSFetchRequest<Message>(entityName: "Message")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "user.id = %@", self.tellemUser!.id!)
        let appDell = UIApplication.shared.delegate as! AppDelegate
        let context = appDell.persistentContainer.viewContext
        let frc = NSFetchedResultsController<Message>(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        
        return frc
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            try fetchedResultsController.performFetch()
            if let previousMessages = fetchedResultsController.sections?[0].objects as? [Message] {
                jsqMessages = convert(messages: previousMessages)
                jsqMessages = jsqMessages?.sorted(by: { $0.date?.compare($1.date as Date) == .orderedAscending })
                collectionView.reloadData()
            }
        } catch let error {
            print(error)
        }
        
        hideKeyboardWhenTappedAround()
        self.title = tellemUser?.name
        self.tabBarController?.tabBar.isHidden = true
        
        outgoingBubbleImageView = bubbleFactory?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleGreen())
        incomingBubbleImageView = bubbleFactory?.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())

        collectionView.collectionViewLayout.incomingAvatarViewSize = .zero
        collectionView.collectionViewLayout.outgoingAvatarViewSize = .zero
        
        automaticallyScrollsToMostRecentMessage = true
        
        self.collectionView?.reloadData()
        self.collectionView?.layoutIfNeeded()
        
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Info", style: .plain, target: self, action: #selector(showContactInfo))
        
        self.inputToolbar.contentView.leftBarButtonItem = nil
        
        tellemUser?.readMessages = Int16((tellemUser?.messages?.count)!)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
        self.navigationItem.backBarButtonItem?.title = "Chat"
        tellemUser?.readMessages = Int16((tellemUser?.messages?.count)!)
    }

    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        let appDell = UIApplication.shared.delegate as! AppDelegate
        let context = appDell.persistentContainer.viewContext
        
        let message = ChatsViewController.createMessage(to: tellemUser!, date: date as NSDate, text: text, context: context, senderId: senderId)
        do {
            try context.save()
            DatabaseService().firebaseUpload(message: message, to: tellemUser!, completion: {
                JSQSystemSoundPlayer.jsq_playMessageSentSound()
            })
        } catch let error {
            print(error)
        }
        
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if type == .insert {
            let message = self.fetchedResultsController.object(at: newIndexPath!) as Message
            self.jsqMessages?.append(self.convert(message: message))
            self.finishSendingMessage(animated: true)
        }
    }
    
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.reloadData()
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        
        return jsqMessages![indexPath.item]
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        let message = jsqMessages?[indexPath.item]
        if message?.senderId != tellemUser?.id {
            cell.textView.textColor = UIColor.white
        } else {
            cell.textView.textColor = UIColor.black
        }
        return cell
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = jsqMessages?[indexPath.item]
        if message?.senderId == FIRAuth.auth()?.currentUser?.uid {
            return outgoingBubbleImageView
        } else {
            return incomingBubbleImageView
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let count = fetchedResultsController.sections?[0].numberOfObjects {
            return count
        }
        return 0
    }
    
    func convert(messages: [Message]?) -> [JSQMessage]? {
        var convertedMessages = [JSQMessage]()
        if messages != nil {
            for message in messages! {
                var sender: String!
                var name: String!
                if message.senderId == senderId {
                    sender = senderId
                    name = UserDefaults().value(forKey: "username") as! String
                } else {
                    sender = tellemUser?.id
                    name = tellemUser?.name
                }
                let jsqMessage = JSQMessage(senderId: sender, senderDisplayName: name, date: message.date as Date!, text: message.text)
                convertedMessages.append(jsqMessage!)
            }
            
        }
        return convertedMessages
    }
    
    func convert(message: Message) -> JSQMessage {
        var sender: String!
        var name: String!
        if message.senderId == senderId {
            sender = senderId
            name = UserDefaults().value(forKey: "username") as! String
        } else {
            sender = tellemUser?.id
            name = tellemUser?.name
        }
        let jsqMessage = JSQMessage(senderId: sender, senderDisplayName: name, date: message.date as Date!, text: message.text)
        return jsqMessage!
    }
    
    func showContactInfo(){
        let contactInfoViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ContactInfoViewController") as! ContactInfoViewController
        contactInfoViewController.tellemUser = self.tellemUser
        navigationController?.pushViewController(contactInfoViewController, animated: true)
        
    }
}
