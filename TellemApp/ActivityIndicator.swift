//
//  ActivityIndicator.swift
//  Tellem
//
//  Created by Rubens Neto on 20/02/17.
//  Copyright © 2017 Rubens Neto. All rights reserved.
//

import UIKit

class ActivityIndicatorController :  UIViewController {
    
    let background = UIView(frame: UIScreen.main.bounds)
    let container = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    var isActive = false
    
    func startActivityIndicator(view: UIView){
        self.isActive = true
        background.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        background.center = self.view.center

        container.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        container.center = self.view.center
        container.layer.cornerRadius = 15
        
        
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        
        view.addSubview(background)
        background.addSubview(container)
        activityIndicator.startAnimating()
        background.addSubview(activityIndicator)
    }
    
    func stopActivityIndicator(){
        self.isActive = false
        activityIndicator.stopAnimating()
        container.removeFromSuperview()
        background.removeFromSuperview()
    }
}
