//
//  ChatsViewController.swift
//  Tellem
//
//  Created by Rubens Neto on 09/02/17.
//  Copyright © 2017 Rubens Neto. All rights reserved.
//

import UIKit
import Firebase

class ChatsViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    var messages: [Message]?
    
    
    override func viewDidLoad() {
        setData()
        collectionView?.alwaysBounceVertical = true
        navigationItem.title = "Chats"
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let count = messages?.count{
            return count
        }
        return 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "chatCell", for: indexPath)
        let imageView = cell.viewWithTag(1) as! UIImageView
        let contactNameLabel = cell.viewWithTag(2) as! UILabel
        let messageLabel = cell.viewWithTag(3) as! UILabel
        let timeLabel = cell.viewWithTag(4) as! UILabel
        
        imageView.layer.cornerRadius = imageView.frame.width / 2
        if let photoURL = messages?[indexPath.row].user?.photoURL{
            imageView.image = UIImage(named: photoURL)
        }
        
        if let name = messages?[indexPath.row].user?.name {
            contactNameLabel.text = name
        }
        
        if let date = messages?[indexPath.row].date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "hh:mm"
            timeLabel.text = dateFormatter.string(from: date as Date)
        }
        
        if let text = messages?[indexPath.row].text {
            messageLabel.text = text
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.view.frame.width, height: 76)
    }
    
}
