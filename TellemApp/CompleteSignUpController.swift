//
//  CompleteSignUpController.swift
//  Tellem
//
//  Created by Rubens Neto on 15/02/17.
//  Copyright © 2017 Rubens Neto. All rights reserved.
//

import UIKit
import Firebase
import GooglePlaces
import SCLAlertView




class CompleteSignUpController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, GMSAutocompleteViewControllerDelegate, CompanyObjectDelegate, UITextViewDelegate, UITextFieldDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var addressTextField: UITextField!
    @IBOutlet weak var businessTextField: UITextField!
    @IBOutlet weak var nextButton: UIButton!
    
    var didSelectedImage: Bool?
    var companyObject = CompanyObject()
    let alertView = SCLAlertView()
    let databaseService = DatabaseService()
    let locationManager = CLLocationManager()
    var delegate: CompanyObjectDelegate? = nil
    var activityIndicator = ActivityIndicatorController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()
        
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
        profileImageView.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(changePhoto)))
        profileImageView.isUserInteractionEnabled = true
        nextButton.layer.cornerRadius = 3
        nextButton.backgroundColor = UIColor(red: 77/255, green: 194/255, blue: 71/255, alpha: 0.3)
        nextButton.isUserInteractionEnabled = false
        businessTextField.text = companyObject.businessField ?? ""
        addressTextField.text = companyObject.formattedAddress ?? ""
        
        if companyObject.isProfessional == false {
            businessTextField.placeholder = "Business (e.g. Restaurant)"
        } else {
            businessTextField.placeholder = "Profession (e.g. Plumber)"
        }
        
    }
    
    // Image picker
    
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
        didSelectedImage = true
        databaseService.updateProfileImage(profilePicture: chosenImage, company: self.companyObject) {
            self.activityIndicator.stopActivityIndicator()
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    
    // Address Picker
    
    @IBAction func findAddress(_ sender: UIButton) {
        let autoCompleteViewController = GMSAutocompleteViewController()
        autoCompleteViewController.delegate = self
        self.present(autoCompleteViewController, animated: true) {
            print("Successfuly Picked up address")
        }
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        dismiss(animated: true) {
            self.addressTextField.text = place.formattedAddress
            self.companyObject.placeID = place.placeID
            self.companyObject.latitude = String(place.coordinate.latitude)
            self.companyObject.longitude = String(place.coordinate.longitude)
            self.companyObject.formattedAddress = place.formattedAddress
            if self.businessTextField.text?.isEmpty != true {
                self.nextButton.isUserInteractionEnabled = true
                self.nextButton.backgroundColor = UIColor(red: 77/255, green: 194/255, blue: 71/255, alpha: 1)
            } else{
                self.nextButton.isUserInteractionEnabled = false
                self.nextButton.backgroundColor = UIColor(red: 77/255, green: 194/255, blue: 71/255, alpha: 0.3)
            }
        }
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        let subTitle = "We are not able to autocomplete your address:"
        alertView.showError("OOPS!", subTitle: "\(subTitle)\n\(error.localizedDescription)")
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // Save Changes
    
    @IBAction func saveChanges(_ sender: UIButton) {
        view.endEditing(true)
        if didSelectedImage != true {
            let subTitle = "Please add an image to your profile."
            alertView.showError("OOPs!", subTitle: subTitle)
        } else if (businessTextField.text?.isEmpty)! ||
            (addressTextField.text?.isEmpty)! {
            let subTitle = "Please fill all the fields with valid data."
            alertView.showError("OOPS!", subTitle: subTitle)
        } else {
            let finishSignUpController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "finishSignUp") as! FinishSignUpController
            self.delegate = finishSignUpController
            
            if delegate != nil {
                finishSignUpController.companyObject = self.companyObject
                navigationController?.pushViewController(finishSignUpController, animated: true)
            }
        }
    }
    
    // UI Stuff
    
    @IBAction func saveBusinessField(_ sender: UITextField) {
        if businessTextField.text?.isEmpty != true {
            self.companyObject.businessField = businessTextField.text!
        }
    }
    
    func fetch(_ companyObject: CompanyObject) {
        self.companyObject = companyObject
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func enableNextButton(_ sender: UITextField) {
        if addressTextField.text?.isEmpty != true &&
            businessTextField.text?.isEmpty != true {
            nextButton.isUserInteractionEnabled = true
            nextButton.backgroundColor = UIColor(red: 77/255, green: 194/255, blue: 71/255, alpha: 1)
        } else{
            nextButton.isUserInteractionEnabled = false
            nextButton.backgroundColor = UIColor(red: 77/255, green: 194/255, blue: 71/255, alpha: 0.3)
        }
    }
}
