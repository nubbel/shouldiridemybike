//
//  ViewController.swift
//  shouldiridemybike
//
//  Created by Dominique d'Argent on 24/04/16.
//  Copyright © 2016 Dominique d'Argent. All rights reserved.
//

import UIKit
import CoreLocation
import WatchConnectivity


class ViewController: UIViewController {

    var urlSession: NSURLSession!
    var locationManager: CLLocationManager!
    var forecastManager: ForecastManager!
    var decisionMaker: DecisionMaker!
    var watchSession: WCSession?
    
    var validWatchSession: WCSession? {
        if let session = watchSession where watchSession?.activationState == .Activated && session.paired && session.watchAppInstalled && session.complicationEnabled {
            return session
        }
        
        return nil
    }
    
    private var state = State.Initial {
        didSet(oldState) {
            if (state != oldState) {
                handleTransitionFromState(oldState)
                
                dispatch_async(dispatch_get_main_queue(), update)
            }
        }
    }
    
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var actionButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        setup()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        state = .Ready
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func setup() {
        urlSession = NSURLSession.sharedSession()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        
        forecastManager = ForecastManager(apiKey: FORECAST_IO_API_KEY, session: urlSession)
        
        decisionMaker = DecisionMaker(
            acceptableTemperatureRange: 5..<30,
            maxAcceptablePrecipitationIntensity: 0.01,
            maxAcceptablePrecipitationProbability: 0.1,
            maxAcceptablePrecipitationUnconditionalIntensity: 0.1,
            maxAcceptableWindSpeed: 15.5
        )
        
        if WCSession.isSupported() {
            watchSession = configure(WCSession.defaultSession()) { session in
                session.delegate = self
                session.activateSession()
            }
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidBecomeActiveNotification, object: nil, queue: nil) { [weak self] (_) in
            self?.state = .Ready
        }
    }
    
    // Must be called on main queue
    func update() {
        statusLabel.text = state.status
        descriptionLabel.text = state.description
        actionButton.setTitle(state.prompt, forState: .Normal)
        actionButton.enabled = state.prompt != nil
    }
    
    func handleTransitionFromState(oldState: State) {
        print("\(oldState) -> \(state)")
        
        let transition = (oldState, state)
        
        switch transition {
        case (_, .Ready):
            if let newState = stateForAuthorizationStatus(CLLocationManager.authorizationStatus()) {
                state = newState
            }
            
        case (.Ready, .Authorized):
            locationManager.requestLocation()
            
        case (_, .LocationUpdated(let location)):
            forecastManager.fetch(location, completionHandler: { (forecast, error) in
                if let error = error {
                    debugPrint("Failed to fetch forecast: \(error)")
                    
                    self.state = .Error
                    return
                }
                
                let decision = self.decisionMaker.makeDecision(forecast.currently)
                
                self.state = .DecisionUpdated(decision)
                
                self.transferComplicationData(forecast)
            })

        default:
            break
        }
    }
    
    func stateForAuthorizationStatus(status: CLAuthorizationStatus) -> State? {
        switch status {
        case .AuthorizedWhenInUse, .AuthorizedAlways:
            return .Authorized
        case .Denied, .Restricted:
            return .Unauthorized
        default:
            return nil
        }
    }
    
    func transferComplicationData(forecast: Forecast) {
        guard let session = validWatchSession else {
            return
        }
        
        let data: [[String: AnyObject]] = forecast.timeline.flatMap { dataPoint in
            guard let decision = decisionMaker.makeDecision(dataPoint) else {
                return nil
            }
            
            return [
                "time": dataPoint.time,
                "decision": "\(decision.result)",
                "reasons": decision.reasons
            ]
        }
        
        let userInfo = ["time": NSDate(), "data": data]
        
        session.transferCurrentComplicationUserInfo(userInfo)
    }
}


// MARK: - Actions
extension ViewController {
    @IBAction func callAction(sender: AnyObject) {
        if let action = state.action {
            switch action {
            case .RequestPermissionFromUser:
                locationManager.requestWhenInUseAuthorization()
            case .Retry:
                state = .Ready
            }
        }
    }
    @IBAction func openForecastWebsite(sender: AnyObject) {
        let url = NSURL(string: "https://forecast.io")!
        UIApplication.sharedApplication().openURL(url)
    }
}

// MARK: - CLLocationManagerDelegate
extension ViewController: CLLocationManagerDelegate {
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if let newState = stateForAuthorizationStatus(status) {
            state = newState
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let currentLocation = locations.last {
            state = .LocationUpdated(Location(
                latitude: currentLocation.coordinate.latitude,
                longitude: currentLocation.coordinate.longitude
            ))
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        state = .Error
    }
}

// MARK: - WCSessionDelegate
extension ViewController: WCSessionDelegate {
    
}
