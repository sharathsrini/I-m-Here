//
//  TableViewController.swift
//  OnTheMap
//
//  Created by Srinivasan, Sharath on 12/13/16.
//  Copyright © 2016 Sharath Srinivasan. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController, Refreshable {
    
    // MARK:- Table View Controller Methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Session.data.studentInformation.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Get a fresh cell
        let cellIdentifier: String = "cell"
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)!
        
        // Decorate & return the cell
        let studentInfo = Session.data.studentInformation[indexPath.row]
        let studentName: String = studentInfo.firstName + " " + studentInfo.lastName
        
        cell.textLabel?.text = studentName
        cell.detailTextLabel?.text = ""
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let studentInfo = Session.data.studentInformation[indexPath.row]
        
        // Jump to Safari and open the sign up link
        if let signUpURL = studentInfo.url {
            UIApplication.shared.open(signUpURL, options: [:], completionHandler: nil)
        }
        
        // Clean up
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    // MARK:- Other Methods
    
    func refresh() {
        self.tableView.reloadData()
    }
    
}
