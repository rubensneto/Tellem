//
//  UserObject.swift
//  Tellem
//
//  Created by Rubens Neto on 12/02/17.
//  Copyright © 2017 Rubens Neto. All rights reserved.
//

import Foundation
import Firebase

class UserObject {
    var name: String!
    var email: String?
    var photoURL: String?
    var ref: FIRDatabaseReference?
    var key: String?
}

class CompanyObject {
    var name: String!
    var email: String!
    var placeID: String!
    var latitude: String!
    var longitude: String!
    var formattedAddress: String!
    var businessDescription: String!
    var businessField: String!
    var photoURL: String!
    var isProfessional: Bool!
    var ref: FIRDatabaseReference?
    var key: String?
    var uid: String!
}
