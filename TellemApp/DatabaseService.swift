//
//  DatabaseService.swift
//  Tellem
//
//  Created by Rubens Neto on 04/02/17.
//  Copyright © 2017 Rubens Neto. All rights reserved.
//

import Foundation
import Firebase
import FBSDKLoginKit
import SCLAlertView


class DatabaseService {
    
    lazy var ref = FIRDatabase.database().reference(fromURL: "https://tellemapp-c58a5.firebaseio.com/")
    let alertView = SCLAlertView()
    
    func isUserAlreadyOnDatabase(user: FIRUser, completion: @escaping () -> ()) {
        let usersRef = ref.child("users")
        usersRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.hasChild(user.uid) {
                print("User is already in database")
                let appDel = UIApplication.shared.delegate as! AppDelegate
                appDel.isLoggedIn()
                return
            }else{
                print("User is being added to database")
                completion()
            }
        })
    }
    
    func firebaseSignInWithFacebook(credentials: FIRAuthCredential, accessToken: FBSDKAccessToken?, result: Any?){
        FIRAuth.auth()?.signIn(with: credentials, completion: { (user, error) in
            if error != nil {
                print("Firebase signin with facebook failed")
            } else {
                print("Successfully Loged in with facebook")
                self.isUserAlreadyOnDatabase(user: user!, completion: {
                    guard let json = result as! NSDictionary? else {
                        print("Cannot convert Json in NSDictionary.")
                        return
                    }
                    //Todo : get facebook picture
                    if let id = json.value(forKey: "id") {
                        let facebookProfileUrl = "http://graph.facebook.com/\(id)/picture?type=large"
                        print(facebookProfileUrl)
                    }
                    DatabaseService().addFacebookUserOnDatabase(user: user!, values: json)
                })
            }
        })
    }
    
    func addFacebookUserOnDatabase(user: FIRUser?, values: NSDictionary?){
        guard let uid = user?.uid else {return}
        let usersRef = self.ref.child("users").child(uid)
        if values != nil {
            usersRef.updateChildValues(values as! [AnyHashable : Any], withCompletionBlock: { (error, databaseRefence) in
                if error != nil {
                    print("Not able to save user on Database:", error!)
                    
                } else {
                    print("Successfully created user in database")
                    UserDefaults.standard.set("user", forKey: "userType")
                    let appDel = UIApplication.shared.delegate as! AppDelegate
                    appDel.isLoggedIn()
                }
            })
        }
    }
    
    func addUserOnDatabase(user: FIRUser, name: String){
        let uid = user.uid
        let usersRef = ref.child("users").child(uid)
        let values: NSDictionary = [
            "name" : name,
            "email" : user.email!
        ]
        usersRef.updateChildValues(values as! [AnyHashable : Any], withCompletionBlock: { (error, databaseRefence) in
            if error != nil {
                print("Not able to save user on Database:", error!)
            } else {
                print("Successfully created user in database")
                UserDefaults.standard.set("user", forKey: "userType")
                let appDel = UIApplication.shared.delegate as! AppDelegate
                appDel.isLoggedIn()
            }
        })
    }
    
    func addCompanyOnDatabase(company: CompanyObject, completion: @escaping () -> ()){
        let values: NSDictionary = [
            "name" : company.name,
            "email" : company.email,
            "placeID" : company.placeID,
            "formattedAddress" : company.formattedAddress,
            "businessField" : company.businessField,
            "businessDescription" : company.businessDescription,
            "photoURL" : company.photoURL
        ]
        
        let companyRef = ref.child(company.child).child(company.uid)
        companyRef.updateChildValues(values as! [AnyHashable : Any], withCompletionBlock: { (error, dataRef) in
            if error != nil {
                let subTitle = "We are not able to create your account at the moment:\n\(error?.localizedDescription)"
                self.alertView.showError("OOPS!", subTitle: subTitle)
            }else{
                print("Successfully created company on database")
                let appDel = UIApplication.shared.delegate as! AppDelegate
                UserDefaults.standard.set("company", forKey: "userType")
                completion()
                appDel.isLoggedIn()
            }
        })
    }
    
    func updateUserOnDatabase(user: UserObject){
        let values: NSDictionary = [
            "photoURL": user.photoURL ?? ""
        ]
        user.ref?.updateChildValues(values as! [AnyHashable : Any], withCompletionBlock: { (error, databaseRefence) in
            if error != nil {
                let subTitle = "We are not able to save your update at the moment:"
               self.alertView.showError("OOPS!", subTitle: "\(subTitle)\n\(error?.localizedDescription)")
            } else {
                print("Successfully updated user in database")
                let appDel = UIApplication.shared.delegate as! AppDelegate
                appDel.isLoggedIn()
            }
        })
    }
    
    func updateProfileImage(profilePicture: UIImage, user: UserObject, completion: @escaping () -> ()){
        let username = user.name.replacingOccurrences(of: " ", with: "")
        if let imageData = UIImageJPEGRepresentation(profilePicture, 0.8){
            let storageRef = FIRStorage.storage().reference().child("\(username)_ProfilePicture.jpg")
            storageRef.put(imageData, metadata: nil, completion: { (metadata, error) in
                if error != nil {
                    let subTitle = "We are not able to upload your image now:"
                    self.alertView.showError("OOPS!", subTitle: "\(subTitle)\n\(error?.localizedDescription)")
                } else {
                    if let profileImageURL = metadata?.downloadURL()?.absoluteString {
                        user.ref?.updateChildValues(["photoURL" : profileImageURL])
                        completion()
                    }
                }
            })
        }
    }
    
    func updateProfileImage(profilePicture: UIImage, company: CompanyObject, completion: @escaping () -> ()){
        let companyName = company.name.replacingOccurrences(of: " ", with: "")
        if let imageData = UIImageJPEGRepresentation(profilePicture, 0.8){
            let storageRef = FIRStorage.storage().reference().child("\(companyName)_ProfilePicture.jpg")
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
}


