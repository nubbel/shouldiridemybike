//
//  ViewController.swift
//  shouldiridemybike
//
//  Created by Dominique d'Argent on 24/04/16.
//  Copyright © 2016 Dominique d'Argent. All rights reserved.
//

import UIKit
import CoreLocation


enum Action {
    case RequestPermissionFromUser
    case Retry
}

enum State {
    case Initial
    case Ready
    case WaitingForAuthorization
    case Authorized
    case Unauthorized
    case LocationUpdated(Location)
    case DecisionUpdated(Decision?)
    case Error
    
    
    var status: String {
        switch self {
        case .Initial:
            return "Waiting…"
        case .Ready:
            return "Where are you?"
        case .WaitingForAuthorization:
            return "̇I'll wait for you."
        case .Authorized:
            return "Trying to find you…"
        case .LocationUpdated:
            return "Checking…"
        case .DecisionUpdated(let decision?) where decision.result == .Yes:
            return "Yes"
        case .DecisionUpdated(let decision?) where decision.result == .No:
            return "No"
        case Error:
            return "Sorry"
        default:
            return ""
        }
    }
    
    var description: String {
        switch self {
        case .Ready:
            return "I need to know where you are in order to figure out the current weather conditions at your location."
        case .DecisionUpdated(let decision?):
            return decision.reason
        case .DecisionUpdated(.None), .Error:
            return "I don't know, just look out of your window."
        default:
            return ""
        }
    }
        
    var prompt: String? {
        switch self {
        case .Ready:
            return "Here I am!"
        case .DecisionUpdated:
            return "And now?"
        case .Error:
            return "Try again!"
        default:
            return nil
        }
    }
    
    var action: Action? {
        switch self {
        case .Ready:
            return .RequestPermissionFromUser
        case .DecisionUpdated, .Error:
            return .Retry
        default:
            return nil
        }
    }
}

class ViewController: UIViewController {

    var session: NSURLSession!
    var locationManager: CLLocationManager!
    var forecastManager: ForecastManager!
    var decisionMaker: DecisionMaker!
    
    private var state = State.Initial {
        didSet(oldState) {
            handleTransitionFromState(oldState)
            
            dispatch_async(dispatch_get_main_queue(), update)
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
        session = NSURLSession.sharedSession()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        
        forecastManager = ForecastManager(apiKey: FORECAST_IO_API_KEY, session: session)
        
        decisionMaker = DecisionMaker(
            acceptableTemperatureRange: 5..<30,
            maxAcceptablePrecipitationIntensity: 0.01,
            maxAcceptablePrecipitationProbability: 0.1,
            maxAcceptablePrecipitationUnconditionalIntensity: 0.1,
            maxAcceptableWindSpeed: 15.5
        )
        
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
