//
//  NetworkRequests.swift
//  OnTheMap
//
//  Created by Srinivasan, Sharath on 12/13/16.
//  Copyright © 2016 Sharath Srinivasan. All rights reserved.
//
import Foundation

class NetworkRequests {
    
    enum Results {
        case success
        case failedForNetworkingError
        case failedForCredentials
    }
    
    // MARK:- Action Methods
    
    func logIn(username: String, password: String, completionHandler: @escaping (Results) -> ()) {
        // Set up request
        var request = URLRequest(url: URL(string: "https://www.udacity.com/api/session")!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = "{\"udacity\": {\"username\": \"\(username)\", \"password\": \"\(password)\"}}".data(using: String.Encoding.utf8)
        
        // Send the request to Udacity
        NSLog("Attemping log in with \(username)")
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            // Catch any communication errors
            if (error != nil) {
                NSLog("Log in failed for networking error: \(error)")
                DispatchQueue.main.async() {
                    completionHandler(Results.failedForNetworkingError)
                }
            }
        
            // Try to parse whatever we received; if we fail, assume that the data was currupted as received
            let subData: Data? = data?.subdata(in: 5..<data!.count)
            guard let parsedData: [String : Any] = self.fromJSONToDict(data: subData) as? [String : Any] else {
                NSLog("Error serializing log in response")
                DispatchQueue.main.async() {
                    completionHandler(Results.failedForNetworkingError)
                }
                return
            }
            
            // Check the intelligble structure
            if let status: Int = parsedData["status"] as? Int, status == 403 {
                NSLog("Log in failed for invalid credentials")
                DispatchQueue.main.async() {
                    completionHandler(Results.failedForCredentials)
                }
            } else {
                // Save the user ID
                if let parsedAccount = parsedData["account"] as? [String : Any], let userID = parsedAccount["key"] as? String {
                    Session.data.userID = userID
                }
                
                NSLog("Log in successful")
                DispatchQueue.main.async() {
                    completionHandler(Results.success)
                }
            }
        }
        task.resume()
    }
    
    func logOut(completionHandler: @escaping (Results) -> ()) {
        // Set up the basic request arguments
        var request = URLRequest(url: URL(string: "https://www.udacity.com/api/session")!)
        request.httpMethod = "DELETE"
        
        // Find the XSRF cookie and attach it
        var xsrfCookie: HTTPCookie? = nil
        if let cookies: [HTTPCookie] = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                if cookie.name == "XSRF-TOKEN" {
                    xsrfCookie = cookie
                }
            }
        }
        if let xsrfCookie = xsrfCookie {
            request.setValue(xsrfCookie.value, forHTTPHeaderField: "X-XSRF-TOKEN")
        }
        
        // Send the request to Udacity
        NSLog("Attemping log out")
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            // Catch any communication errors
            if (error != nil) {
                NSLog("Log out failed for networking error: \(error)")
                DispatchQueue.main.async() {
                    completionHandler(Results.failedForNetworkingError)
                }
                return
            }
            
            // Assumming at this point that the logout was sucessful; if it wasn't for whatever (unlikely) reason, the user will simply create a new session on the next login and the current one will expire on it's own
            NSLog("Log out presumed successful")
            DispatchQueue.main.async() {
                completionHandler(Results.success)
            }
        }
        task.resume()
    }
    
    func refreshStudentInformation(completionHandler: @escaping (Results) -> ()) {
        // Set up the request; assume for now that we will only ever want the last 100 students, from most to least recent
        var url: String = "https://parse.udacity.com/parse/classes/StudentLocation?"
        url.append("limit=100&")
        url.append("order=-updatedAt")
        
        var request = URLRequest(url: URL(string: url)!)
        request.addValue("QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr", forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue("QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY", forHTTPHeaderField: "X-Parse-REST-API-Key")
        
        // Send the request to Udacity
        NSLog("Refreshing last 100 student posts")
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            // Catch any communication errors
            if (error != nil) {
                NSLog("Refresh failed for networking error: \(error)")
                DispatchQueue.main.async() {
                    completionHandler(Results.failedForNetworkingError)
                }
                return
            }
            
            // Try to parse whatever we received; if we fail, assume that the data was currupted as received
            guard let parsedData: [String : Any] = self.fromJSONToDict(data: data) as? [String : Any] else {
                NSLog("Error serializing refresh response")
                DispatchQueue.main.async() {
                    completionHandler(Results.failedForNetworkingError)
                }
                return
            }
            
            guard let results = parsedData["results"] as? [[String : Any]] else {
                NSLog("No results in the response")
                DispatchQueue.main.async() {
                    completionHandler(Results.failedForNetworkingError)
                }
                return
            }
            
            // Check for actual post fields; save those that we get
            var newStudentInfo: [StudentInformation] = []
            for result: [String : Any] in results {
                let newStudentInfoEntry: StudentInformation = StudentInformation(data: result)
                newStudentInfo.append(newStudentInfoEntry)
            }
            
            Session.data.studentInformation.removeAll()
            Session.data.studentInformation.append(contentsOf: newStudentInfo)
            
            NSLog("Refresh successful, \(Session.data.studentInformation.count) entries added")
            DispatchQueue.main.async() {
                completionHandler(Results.success)
            }
        }
        task.resume()
    }
    
    func getUserInformation(completionHandler: @escaping (Results) -> ()) {
        // Set up the request
        var url: String = "https://www.udacity.com/api/users/"
        url.append(Session.data.userID)
        
        let request = URLRequest(url: URL(string: url)!)
        
        // Send the request to Udacity
        NSLog("Getting user information")
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            // Catch any communication errors
            if (error != nil) {
                NSLog("Getting failed for networking error: \(error)")
                DispatchQueue.main.async() {
                    completionHandler(Results.failedForNetworkingError)
                }
                return
            }
            
            // Try to parse whatever we received; if we fail, assume that the data was currupted as received
            let subData: Data? = data?.subdata(in: 5..<data!.count)
            guard let parsedData: [String : Any] = self.fromJSONToDict(data: subData) as? [String : Any] else {
                NSLog("Error serializing get response")
                DispatchQueue.main.async() {
                    completionHandler(Results.failedForNetworkingError)
                }
                return
            }
            
            // Save the user name
            if let parserUser = parsedData["user"] as? [String : Any] {
                if let userFirstName = parserUser["first_name"] as? String {
                    Session.data.userFirstName = userFirstName
                }
                
                if let userLastName = parserUser["last_name"] as? String {
                    Session.data.userLastName = userLastName
                }
            }
            
            NSLog("Get successful")
            DispatchQueue.main.async() {
                completionHandler(Results.success)
            }
        }
        task.resume()
    }
    
    func postStudentInformation(locationName: String, latitude: Double, logitude: Double, userURL: String, completionHandler: @escaping (Results) -> ()) {
        // Set up the basic request arguments
        var request = URLRequest(url: URL(string: "https://parse.udacity.com/parse/classes/StudentLocation")!)
        request.httpMethod = "POST"
        request.addValue("QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr", forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue("QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY", forHTTPHeaderField: "X-Parse-REST-API-Key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add the post content
        let requestBody =
            "{" +
                "\"uniqueKey\": \"\(Session.data.userID)\"," +
                "\"firstName\": \"\(Session.data.userFirstName)\"," +
                "\"lastName\": \"\(Session.data.userLastName)\"," +
                "\"mapString\": \"\(locationName)\"," +
                "\"mediaURL\": \"\(userURL)\"," +
                "\"latitude\": \(latitude)," +
                "\"longitude\": \(logitude)" +
            "}"
        request.httpBody = requestBody.data(using: String.Encoding.utf8)
            
        // Send the request to Udacity
        NSLog("Posting")
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            // Catch any communication errors
            if (error != nil) {
                NSLog("Posting failed for networking error: \(error)")
                DispatchQueue.main.async() {
                    completionHandler(Results.failedForNetworkingError)
                }
                return
            }
            
            // -- DEBUG
            
            // Try to parse whatever we received; if we fail, assume that the data was currupted as received
            guard let parsedData: [String : Any] = self.fromJSONToDict(data: data) as? [String : Any] else {
                NSLog("Error serializing get response")
                DispatchQueue.main.async() {
                    completionHandler(Results.failedForNetworkingError)
                }
                return
            }
            
            NSLog(parsedData.description)
            
            // -- END DEBUG
            
            // Assumming at this point that the post was sucessful
            NSLog("Posting presumed successful")
            DispatchQueue.main.async() {
                completionHandler(Results.success)
            }
        }
        task.resume()
    }
    
    // MARK:- Other Methods
    
    func fromJSONToDict(data: Data?) -> Any? {
        guard let data = data else {
            return nil
        }
        
        do {
            let dict = try JSONSerialization.jsonObject(with: data)
            return dict
        } catch {
            return nil
        }
    }
    
}
