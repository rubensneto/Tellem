//
//  ContactsViewController.swift
//  Tellem
//
//  Created by Rubens Neto on 14/02/17.
//  Copyright © 2017 Rubens Neto. All rights reserved.
//

import UIKit

class ContactsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBarItem.isEnabled = true
        tabBarController?.tabBar.isHidden = false
    }
}
