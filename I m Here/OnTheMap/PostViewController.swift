//
//  PostViewController.swift
//  OnTheMap
//
//  Created by Srinivasan, Sharath on 12/13/16.
//  Copyright © 2016 Sharath Srinivasan. All rights reserved.
//
import UIKit
import MapKit
import CoreLocation

class PostViewController: UITableViewController {
    
    weak var locationField: UITextField!
    weak var map: MKMapView!
    weak var urlField: UITextField!
    weak var doneButton: UIButton!
    
    let geocoder: CLGeocoder = CLGeocoder()
    var locationCoordinates: CLLocationCoordinate2D? = nil
    var locationShown: Bool = false

    // MARK:- Table View Controller Methods

    override func numberOfSections(in tableView: UITableView) -> Int {
        // Sections for location, url, and submit/cancel buttons
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            // Map cell count changes depending on text field content
            return (locationShown ? 2 : 1)
        case 1:
            // One cell to URL
            return 1
        case 2:
            // Two cells for the buttons (one per)
            return 2
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Determine the correct cell
        var cellIdentifier: String = ""
        switch (indexPath.section, indexPath.row) {
        case (0,0):
            cellIdentifier = "location"
        case (0,1):
            cellIdentifier = "map"
        case (1,0):
            cellIdentifier = "url"
        case (2,0):
            cellIdentifier = "done"
        case (2,1):
            cellIdentifier = "cancel"
        default:
            break
        }
        
        // Get a fresh cell
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)!
        
        // TODO: Decorate & return the cell
        switch cellIdentifier {
        case "location":
            if let view = cell.contentView.viewWithTag(1) as? UITextField {
                locationField = view
            }
        case "map":
            if let view = cell.contentView.viewWithTag(2) as? MKMapView {
                map = view
            }
        case "url":
            if let view = cell.contentView.viewWithTag(3) as? UITextField {
                urlField = view
            }
        case "done":
            if let view = cell.contentView.viewWithTag(4) as? UIButton {
                doneButton = view
            }
        default:
            break
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Specify a custom height for the Map cell
        if indexPath.section == 0 && indexPath.row == 1 {
            return 268.0
        } else {
            return UITableViewAutomaticDimension
        }
    }
    
    // MARK:- UI Methods
    
    @IBAction func textFieldUpdated(sender: AnyObject) {
        enableDone()
    }
    
    @IBAction func textFieldDone(sender: UITextField) {
        print("textFieldDone IBAction called")
        
        // For either text field, drop the keyboard and end editing
        sender.resignFirstResponder()
        
        // For the location field, look up the location
        if sender.tag == 1 {
            // Validation, before we update any UI
            if locationField.text!.isEmpty {
                self.showFailureAlert(
                    title: NSLocalizedString("NoLocationFailureTitle", comment: "No Location failure alert title"),
                    message: NSLocalizedString("NoLocationFailure", comment: "No Location failure text"))
                return
            }
            
            // Show the map cell, if hasn't been shown already
            if !locationShown {
                locationShown = true
                tableView.beginUpdates()
                tableView.insertRows(at: [IndexPath(row: 1, section: 0)], with: .automatic)
                tableView.endUpdates()
            }
            
            // Setup the UI
            setNetworkActivityStatus(active: true)
            
            // Look up the given location name
            geocoder.geocodeAddressString(locationField.text!) {(placemarks: [CLPlacemark]?, error: Error?) in
                // Clean up the UI
                self.setNetworkActivityStatus(active: false)
                
                // More validation, before we change pins
                guard let placemarks = placemarks, placemarks.count > 0, error == nil else {
                    self.showFailureAlert(
                        title: NSLocalizedString("LocationNotFoundFailureTitle", comment: "Location not found failure alert title"),
                        message: NSLocalizedString("LocationNotFoundFailure", comment: "Location not found failure text"))
                    return
                }
                
                // Remove any prior annotations
                self.map.removeAnnotations(self.map.annotations)
                
                // Add an annotation for the newly resolved location
                let annotation: MKPointAnnotation = MKPointAnnotation()
                annotation.coordinate = placemarks[0].location!.coordinate
                
                self.map.addAnnotation(annotation)
                self.map.setCenter(annotation.coordinate, animated: true)
                
                self.locationCoordinates = annotation.coordinate
                self.enableDone()
            }
        }
    }
    
    @IBAction func done(sender: UIButton) {
        print("done IBAction called")
        done()
    }
    
    @IBAction func cancel(sender: UIButton) {
        print("cancel IBAction called")
        close()
    }
    
    // MARK:- Other Methods
    
    func enableDone() {
        doneButton.isEnabled = !(urlField.text!.isEmpty) && (locationCoordinates != nil)
    }
    
    func done() {
        let location: String = locationField.text!
        let url: String = urlField.text!
        let latitude: Double = locationCoordinates!.latitude
        let logitude: Double = locationCoordinates!.longitude
        
        // Setup the UI
        setNetworkActivityStatus(active: true)
        
        // Make the call to refresh the user info
        Session.networkRequests.getUserInformation() { (getResult) in
            // Clean up the UI
            self.setNetworkActivityStatus(active: false)
            
            // Handle the get outcome
            switch getResult {
            case NetworkRequests.Results.success:
                self.post(location: location, url: url, latitude: latitude, logitude: logitude)
            case NetworkRequests.Results.failedForNetworkingError:
                self.showFailureAlert(
                    title: NSLocalizedString("PostFailureTitle", comment: "Posting failure alert title"),
                    message: NSLocalizedString("NetworkFailure", comment: "Network failure text"))
            default:
                break
            }
        }
    }
    
    func post(location: String, url: String, latitude: Double, logitude: Double) {
        // Setup the UI
        setNetworkActivityStatus(active: true)
        
        // Make the call to refresh the user info
        Session.networkRequests.postStudentInformation(locationName: location, latitude: latitude, logitude: logitude, userURL: url) { (getResult) in
            // Clean up the UI
            self.setNetworkActivityStatus(active: false)
            
            // Handle the get outcome
            switch getResult {
            case NetworkRequests.Results.success:
                self.close()
            case NetworkRequests.Results.failedForNetworkingError:
                self.showFailureAlert(
                    title: NSLocalizedString("PostFailureTitle", comment: "Posting failure alert title"),
                    message: NSLocalizedString("NetworkFailure", comment: "Network failure text"))
            default:
                break
            }
        }
    }
    
    func close() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func showFailureAlert(title: String, message: String) {
        // Construct the alert ingredients
        let alertController: UIAlertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle:UIAlertControllerStyle.alert)
        let alertAction: UIAlertAction = UIAlertAction(
            title: NSLocalizedString("OK", comment: "Not good-OK, not bad-OK, just OK-OK"),
            style: UIAlertActionStyle.default,
            handler: nil)
        
        // Showtime!
        alertController.addAction(alertAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func setNetworkActivityStatus(active: Bool) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = active
        view.isUserInteractionEnabled = !active
    }

}
