//
//  DatabaseService.swift
//  Tellem
//
//  Created by Rubens Neto on 04/02/17.
//  Copyright © 2017 Rubens Neto. All rights reserved.
//

import Foundation
import Firebase
import SCLAlertView


class DatabaseService {
    
    lazy var ref = FIRDatabase.database().reference(fromURL: "Your Firebase database URL here.")
    let alertView = SCLAlertView()
    
    
   func addCompanyOnDatabase(company: CompanyObject, completion: @escaping () -> ()){
        let values: NSDictionary = [
            "name" : company.name,
            "email" : company.email,
            "placeID" : company.placeID,
            "latitude" : company.latitude,
            "longitude" : company.longitude,
            "formattedAddress" : company.formattedAddress,
            "businessField" : company.businessField,
            "businessDescription" : company.businessDescription,
            "photoURL" : company.photoURL,
            "isProfessional" : company.isProfessional
        ]
        
        let companyRef = ref.child("users").child(company.uid)
        companyRef.updateChildValues(values as! [AnyHashable : Any], withCompletionBlock: { (error, dataRef) in
            if error != nil {
                print(error!.localizedDescription)
            } else {
                print("Successfully created company on database")
                let appDel = UIApplication.shared.delegate as! AppDelegate
                UserDefaults.standard.set("company", forKey: "userType")
                completion()
                appDel.isLoggedIn()
            }
        })
    }
    
    func deleteAccount(viewController: UIViewController){
        let userId = UserDefaults().value(forKey: "userId") as! String
        let userRef = ref.child("users").child(userId)
        let receiverMessages = ref.child("receiverMessages").child(userId)
        receiverMessages.observe(.childAdded, with: { (snapshot) in
            let messagesRef = self.ref.child("messages").child(snapshot.value! as! String)
            messagesRef.removeValue()

        }) { (error) in
            print(error)
        }
        userRef.removeValue()
        let photoRef = FIRStorage.storage().reference().child("\(userId)_ProfilePicture.jpg")
        photoRef.delete { (error) in
            if error != nil {
                print(error!)
            }
        }
        
        let user = FIRAuth.auth()?.currentUser
        user?.delete { error in
            if let error = error {
                let subTitle = "We are not able to delete your account at the moment:"
                self.alertView.showError("OOPS!", subTitle: "\(subTitle)\n\(error.localizedDescription)")
            } else {
                let loginController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "loginNavigationController") as! UINavigationController
                viewController.present(loginController, animated: true, completion: nil)
            }
        }
    }
    
    
    func updateProfileImage(profilePicture: UIImage, company: CompanyObject, completion: @escaping () -> ()){
        guard let userId = UserDefaults().value(forKey: "userId") as? String else {
            return
        }
        
        if let imageData = UIImageJPEGRepresentation(profilePicture, 0.8){
            let storageRef = FIRStorage.storage().reference().child("\(userId)_ProfilePicture.jpg")
            storageRef.put(imageData, metadata: nil, completion: { (metadata, error) in
                if error != nil {
                    let subTitle = "We are not able to upload your image now:"
                    self.alertView.showError("OOPS!", subTitle: "\(subTitle)\n\(error?.localizedDescription)")
                } else {
                    if let profileImageURL = metadata?.downloadURL()?.absoluteString {
                        company.ref?.updateChildValues(["photoURL" : profileImageURL])
                        company.photoURL = profileImageURL
                        completion()
                    }
                }
            })
        }
    }
    
    func retrieveProfileImage(from url: String, to imageView: UIImageView){
        if url != ""{
            FIRStorage.storage().reference(forURL: url).data(withMaxSize: 1 * 1024 * 1024, completion: { (imageData, error) in
                if error != nil {
                    print(error!.localizedDescription)
                } else {
                    if let data = imageData {
                        imageView.image = UIImage(data: data)
                    }
                }
            })
        }
    }
    
    func firebaseUpload(message: Message, to user: TellemUser, completion: @escaping () -> ()){
        let usersRef = ref.child("users")
        usersRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.hasChild(user.id!){
                let messagesRef = self.ref.child("messages")
                let childRef = messagesRef.childByAutoId()
                let timestamp = Int((message.date?.timeIntervalSince1970)!) as NSNumber
                if let senderId = UserDefaults().value(forKey: "userId") as? String {
                    let values: [String : Any] = ["text": message.text!,
                                                  "timestamp": timestamp,
                                                  "senderId": senderId,
                                                  "senderName": UserDefaults().value(forKey: "username") as! String,
                                                  "receiverId": user.id!]
                    childRef.updateChildValues(values, withCompletionBlock: { (error, reference) in
                        if error != nil {
                            print(error!)
                        } else {
                            let receiverMessagesRef = FIRDatabase.database().reference().child("receiverMessages").child(user.id!)
                            let messageId = childRef.key
                            receiverMessagesRef.updateChildValues([messageId : 1])
                            completion()
                        }
                    })
                }
            }
        }) { (error) in
            print(error)
        }
    }
}


