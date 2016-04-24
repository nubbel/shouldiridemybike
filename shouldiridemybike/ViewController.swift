//
//  ViewController.swift
//  shouldiridemybike
//
//  Created by Dominique d'Argent on 24/04/16.
//  Copyright © 2016 Dominique d'Argent. All rights reserved.
//

import UIKit
import CoreLocation

enum State {
    case Init
    case LocationUpdated(Location)
}

class ViewController: UIViewController {

    var session: NSURLSession!
    var locationManager: CLLocationManager!
    var forecastManager: ForecastManager!
    
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var actionButton: UIButton!
    
    var action: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        setup()
        
        update(.Init)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func setup() {
        session = NSURLSession.sharedSession()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        
        forecastManager = ForecastManager(apiKey: FORECAST_IO_API_KEY, session: session)
    }
    
    func update(state: State) {
        switch state {
        case .Init:
            statusLabel.text = "Where are you?"
            descriptionLabel.text = "I need to know where you are in order to figure out the current weather conditions at your location."
            actionButton.setTitle("Here I am!", forState: .Normal)
            action = requestLocation
            
        case .LocationUpdated(let location):
            statusLabel.text = "Checking…"
            descriptionLabel.text = "Let me see."
            actionButton.hidden = true
            action = nil
            forecastManager.fetch(location, completionHandler: { json in
                print("forecast: \(json)")
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.statusLabel.text = "No"
                    self.descriptionLabel.text = "The weather sucks!"
                    self.actionButton.hidden = true
                }
            })
            
        }
        
    }
}


// MARK: - Actions
extension ViewController {
    @IBAction func callAction(sender: AnyObject) {
        if let action = action {
            action()
        }
    }
    
    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
    
}

// MARK: - CLLocationManagerDelegate
extension ViewController: CLLocationManagerDelegate {
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let currentLocation = locations.last {
            update(.LocationUpdated(Location(
                latitude: currentLocation.coordinate.latitude,
                longitude: currentLocation.coordinate.longitude
            )))
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        
    }
}
