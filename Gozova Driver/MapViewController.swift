//
//  MapViewController.swift
//  Gozova Driver
//
//  Created by Cameron Moreau on 4/12/16.
//  Copyright © 2016 Gozova. All rights reserved.
//

import UIKit
import MapKit
import SCLAlertView

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBAction func btnStartPressed(sender: UIButton) {
        self.toggleDrivingMode()
        if drivingMode {
            self.requestRecieved()
        }
    }
    
    @IBOutlet weak var btnStart: UIButton!
    @IBOutlet weak var map: MKMapView!
    
    let locationManager = CLLocationManager()
    var drivingMode = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Title view
        let logo = UIImage(named: "logo")
        let imageView = UIImageView(image: logo)
        imageView.contentMode = .ScaleAspectFit;
        imageView.frame = CGRectMake(0, 0, imageView.frame.width, 35)
        
        //Navigation
        self.navigationController?.navigationBar.translucent = false
        
        self.navigationItem.titleView = imageView
        
        //Location stuff
        if CLLocationManager.locationServicesEnabled() {
            setupLocation()
        } else {
            print("Location not enabled")
            locationManager.requestAlwaysAuthorization()
        }
        
        self.map.delegate = self
    }
    
    func setupLocation() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    // Mark: - Until
    func toggleDrivingMode() {
        drivingMode = !drivingMode
        
        if drivingMode {
            btnStart.backgroundColor = UIColor.redColor()
            btnStart.setTitle("Done for the day", forState: .Normal)
        } else {
            btnStart.backgroundColor = UIColor.mainColor()
            btnStart.setTitle("Start Driving Mode", forState: .Normal)
        }
    }
    
    func requestRecieved() {
        let alert = SCLAlertView()
        alert.addButton("Accept") {
            self.requestAccepted()
        }
        
        alert.showTitle(
            "Pickup Request",
            subTitle: "Some request",
            duration: 5.0,
            completeText: "Dismiss",
            style: .Wait,
            colorStyle: 0x40DCC2,
            colorTextButton: 0xFFFFFF
        )
    }
    
    func requestAccepted() {
        self.map.removeAnnotations(self.map.annotations)
        self.map.removeOverlays(self.map.overlays)
        
        let current = (self.locationManager.location?.coordinate)!
        let fake = self.generateFakeLocation()
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = fake
        annotation.title = "Destination"
        annotation.subtitle = "\(fake.latitude), \(fake.longitude)"
        self.map.addAnnotation(annotation)
        self.map.selectAnnotation(annotation, animated: true)
        
        //Draw lines -- need to free points
        var points = [current, fake]
        let route = MKPolyline(coordinates: &points, count: points.count)
        self.map.addOverlay(route)
        
        self.zoomMapToBounds(current, end: fake)
    }
    
    // Mark: - Helper functions
    
    func generateFakeLocation() -> CLLocationCoordinate2D {
        if let location = locationManager.location {
            let rLat = (Double(arc4random_uniform(30)) - 15) / 100
            let rLng = (Double(arc4random_uniform(30)) - 15) / 100
            
            let randomCord = CLLocationCoordinate2DMake(location.coordinate.latitude + rLat, location.coordinate.longitude + rLng)
            
            return randomCord
        }
        
        return CLLocationCoordinate2DMake(0, 0)
    }
    
    func zoomMapToBounds(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D) {
        let topLeftLat = max(start.latitude, end.latitude)
        let topLeftLng = min(start.longitude, end.longitude)
        
        let bottomRightLat = min(start.latitude, end.latitude)
        let bottomRightLng = max(start.longitude, end.longitude)
        
        let centerLat = topLeftLat - (topLeftLat - bottomRightLat) * 0.5
        let centerLng = topLeftLng + (bottomRightLng - topLeftLng) * 0.5
        
        let spanLat = abs(topLeftLat - bottomRightLat) * 1.8
        let spanLng = abs(bottomRightLng - topLeftLng) * 1.8
        
        let center = CLLocationCoordinate2DMake(centerLat, centerLng)
        let span = MKCoordinateSpanMake(spanLat, spanLng)
        
        var region = MKCoordinateRegionMake(center, span)
        region = self.map.regionThatFits(region)
        self.map.setRegion(region, animated: true)
    }

    // MARK: - Location Delegate
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let zoom = 0.1
            
            let region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: zoom, longitudeDelta: zoom))
            self.map.setRegion(region, animated: true)
            
            
            locationManager.stopUpdatingLocation()
        }
    }
    
    // MARK: - Map Delegate
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let view = MKPolylineRenderer(overlay: overlay)
            view.strokeColor = UIColor.mainColor()
            view.lineWidth = 3
            return view
        }
        
        return MKPolylineRenderer()
    }
}
