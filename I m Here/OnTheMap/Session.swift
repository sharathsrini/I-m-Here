//
//  SessionData.swift
//  OnTheMap
//
//  Created by Srinivasan, Sharath on 12/13/16.
//  Copyright © 2016 Sharath Srinivasan. All rights reserved.
//

import Foundation

class Session {
    
    class Data {
        var userID: String = ""
        var userFirstName: String = ""
        var userLastName: String = ""
        var studentInformation: [StudentInformation] = []
    }
    
    // Globally accessible, consistent model instances
    static let data: Data = Data()
    static let networkRequests: NetworkRequests = NetworkRequests()
    
}
