//
//  SettingsViewController.swift
//  Tellem
//
//  Created by Rubens Neto on 14/02/17.
//  Copyright © 2017 Rubens Neto. All rights reserved.
//

import UIKit
import Firebase
import SCLAlertView
import GooglePlaces

class AccountViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, GMSAutocompleteViewControllerDelegate {
    
    let userId = UserDefaults().value(forKey: "userId") as! String

    let databaseService = DatabaseService()
    let alertView = SCLAlertView()
    let companyObject = CompanyObject()
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var bussinessLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    let activityIndicator = ActivityIndicatorController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBarItem.isEnabled = true
        
        tabBarController?.tabBar.isHidden = false
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
        profileImageView.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(changePhoto)))
        profileImageView.isUserInteractionEnabled = true
        
        let userRef = FIRDatabase.database().reference().child("users").child(userId)
        
        userRef.observeSingleEvent(of: .value, with: { (snapshot) in
            self.companyObject.ref = snapshot.ref
            let userDictionary = snapshot.value as! [String : AnyObject]
            self.nameLabel.text = userDictionary["name"] as! String? ?? UserDefaults().value(forKey: "username") as! String?
            self.bussinessLabel.text = userDictionary["businessField"] as? String? ?? ""
            self.addressLabel.text = userDictionary["formattedAddress"] as? String? ?? ""
            self.descriptionLabel.text = userDictionary["businessDescription"] as? String? ?? ""
            if let photoURL = userDictionary["photoURL"] as? String {
                self.profileImageView.loadImageUsingCacheWith(urlString: photoURL)
            }
        }) { (error) in
            print(error.localizedDescription)
        }

    }

    @IBAction func deleteAccount(_ sender: UIButton) {
        let alertSheet = UIAlertController(title: "Confirm Delete", message: "Your account will be deleted permanently!", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (action) in
            let textField = alertSheet.textFields![0] as UITextField
            let email = FIRAuth.auth()?.currentUser?.email
            if (textField.text?.characters.count)! > 5 {
                do {
                    try FIRAuth.auth()!.signOut()
                } catch let error {
                    print(error)
                }
                FIRAuth.auth()?.signIn(withEmail: email!, password: textField.text!, completion: { (user, error) in
                    if error != nil {
                        print(error!)
                    } else {
                        self.databaseService.deleteAccount(viewController: self)
                        ChatsViewController.clearEntities("TellemUser")
                        ChatsViewController.clearEntities("Message")
                    }
                })
            }
        }
        alertSheet.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Enter Your Password"
        }
        alertSheet.addAction(cancelAction)
        alertSheet.addAction(deleteAction)
        self.present(alertSheet, animated: true)
    }
    
   
    
    @IBAction func editProfession(_ sender: UIButton) {
        edit(label: self.bussinessLabel, childValue: "businessField", alertTitle: "Change ocuppation", message: "", placeHolder: "Enter your ocuppation")
    }
    
    @IBAction func editAddress(_ sender: UIButton) {
        let autoCompleteViewController = GMSAutocompleteViewController()
        autoCompleteViewController.delegate = self
        self.present(autoCompleteViewController, animated: true) {
            print("Successfuly Picked up address")
        }
    }
    
    @IBAction func editDescription(_ sender: UIButton) {
        edit(label: self.descriptionLabel, childValue: "businessDescription", alertTitle: "Change Description", message: "Enter a short description about your job or business.", placeHolder: "Enter Description")
    }
    
    //Image Piker
    
    func changePhoto(){
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        let actionSheet = UIAlertController(title: "Update your image", message: "Choose option", preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { (action) in
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
                imagePicker.sourceType = UIImagePickerControllerSourceType.camera;
                imagePicker.allowsEditing = true
                imagePicker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
                self.present(imagePicker, animated: true, completion: nil)
            }
        }
        
        let libraryAction = UIAlertAction(title: "Library", style: .default) { (action) in
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary) {
                imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary;
                imagePicker.allowsEditing = true
                self.present(imagePicker, animated: true, completion: nil)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        actionSheet.addAction(cameraAction)
        actionSheet.addAction(libraryAction)
        actionSheet.addAction(cancelAction)
        
        self.present(actionSheet, animated: true) {
            print("actionSheet")
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        self.dismiss(animated:true, completion: nil)
        activityIndicator.startActivityIndicator(view: self.view)
        let chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        profileImageView.image = chosenImage
        databaseService.updateProfileImage(profilePicture: chosenImage, company: self.companyObject) {
            self.activityIndicator.stopActivityIndicator()
            let userRef = FIRDatabase.database().reference().child("users").child(self.userId)
            userRef.updateChildValues(["photoURL": self.companyObject.photoURL])
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func edit(label: UILabel, childValue: String, alertTitle: String, message: String, placeHolder: String) {
        let userRef = FIRDatabase.database().reference().child("users").child(userId)
        
        let alertSheet = UIAlertController(title: alertTitle, message: message, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let doneAction = UIAlertAction(title: "Done", style: .default) { (action) in
            let textField = alertSheet.textFields![0] as UITextField
            if (textField.text?.characters.count)! > 4 {
                userRef.updateChildValues([childValue : textField.text!])
                label.text = textField.text!
            }
        }
        alertSheet.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = placeHolder
        }
        alertSheet.addAction(cancelAction)
        alertSheet.addAction(doneAction)
        self.present(alertSheet, animated: true)
    }
    
    //Address Picker
    
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        dismiss(animated: true) {
            
            let userRef = FIRDatabase.database().reference().child("users").child(self.userId)
            self.addressLabel.text = place.formattedAddress
            userRef.updateChildValues(["formattedAddress" : place.formattedAddress!])
            userRef.updateChildValues(["placeID" : place.placeID])
            userRef.updateChildValues(["latitude" : place.coordinate.latitude as NSNumber])
            userRef.updateChildValues(["longitude" : place.coordinate.longitude as NSNumber])
            UserDefaults().setValue(place.coordinate.latitude, forKey: "userLatitude")
            UserDefaults().setValue(place.coordinate.longitude, forKey: "userLongitude")
        }
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        let subTitle = "We are not able to autocomplete your address:"
        alertView.showError("OOPS!", subTitle: "\(subTitle)\n\(error.localizedDescription)")
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }

}































