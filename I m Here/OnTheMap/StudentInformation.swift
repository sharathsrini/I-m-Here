//
//  StudentInformation.swift
//  OnTheMap
//
//  Created by Srinivasan, Sharath on 12/13/16.
//  Copyright © 2016 Sharath Srinivasan. All rights reserved.
//

import Foundation
import MapKit

struct StudentInformation {

    var uniqueKey: String?
    
    var firstName: String
    var lastName: String
    
    var location: String
    var latitude: Double
    var longitude: Double
    
    var url: URL?
    
    init(data: [String : Any]) {
        // The input should be a Udacity StudentLocation (multiple) GET API response; not all response (or structure) fields are saved, only those necessary for listing.
        if let firstName = data["firstName"] as? String {
            self.firstName = firstName
        } else {
            self.firstName = ""
        }
        
        if let lastName = data["lastName"] as? String {
            self.lastName = lastName
        } else {
            self.lastName = ""
        }
        
        if let location = data["mapString"] as? String {
            self.location = location
        } else {
            self.location = ""
        }
        
        if let latitude = data["latitude"] as? Double {
            self.latitude = latitude
        } else {
            self.latitude = 0.0
        }
        
        if let longitude = data["longitude"] as? Double {
            self.longitude = longitude
        } else {
            self.longitude = 0.0
        }
        
        if let url = data["mediaURL"] as? String {
            self.url = URL(string: url)
        } else {
            self.url = nil
            
        }
    }
    
    func asDictionary() -> [String : Any] {
        // Return a dictionary ready to be converted to JSON and passed to the Udacity StudentLocation APIs
        var dict: [String : Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "location": location,
            "latitude": latitude,
            "longitude": longitude
        ]
        
        // The API will fail if these aren't set, but we'll handle that later
        if let uniqueKey = self.uniqueKey {
            dict["uniqueKey"] = uniqueKey
        }
        
        if let url = self.url {
            dict["mediaURL"] = url.absoluteString
        }
        
        return dict
    }
    
}
