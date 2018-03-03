//
//  MapViewController.swift
//  OnTheMap
//
//  Created by Srinivasan, Sharath on 12/13/16.
//  Copyright © 2016 Sharath Srinivasan. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate, Refreshable {
    
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK:- Map View Delegate Methods
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseIdentifier = "pin"
        
        var annotationView: MKAnnotationView? = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
        if let annotationView = annotationView {
            annotationView.annotation = annotation
        } else {
            let newAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            newAnnotationView.canShowCallout = true
            newAnnotationView.rightCalloutAccessoryView = UIButton.init(type: .detailDisclosure)
            annotationView = newAnnotationView
        }
        
        return annotationView
    }
    
    // When user taps on the disclosure button you can perform a segue to navigate to another view controller
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            guard let annotation = view.annotation, let detailString = annotation.subtitle! else {
                NSLog("Error getting student information from map annotation view")
                return
            }
            
            // Jump to Safari and open the sign up link
            if let signUpURL = URL(string: detailString) {
                UIApplication.shared.open(signUpURL, options: [:], completionHandler: nil)
            }
        }
    }

    // MARK:- Other Methods

    func refresh() {
        // Clear out the old pins
        mapView.removeAnnotations(mapView.annotations)
        
        // Add the new pins
        for instance: StudentInformation in Session.data.studentInformation {
            // Prep the data
            let studentName: String = instance.firstName + " " + instance.lastName
            guard let studentURL: String = instance.url?.absoluteString else {
                continue
            }
            
            // Create the annotation
            let annotation: MKPointAnnotation = MKPointAnnotation()
            annotation.title = studentName
            annotation.subtitle = studentURL
            annotation.coordinate = CLLocationCoordinate2D(latitude: instance.latitude, longitude: instance.longitude)
            
            // Add the annotation
            mapView.addAnnotation(annotation)
        }
    }
    
}
