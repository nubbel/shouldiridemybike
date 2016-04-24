//
//  ForecastManager.swift
//  shouldiridemybike
//
//  Created by Dominique d'Argent on 24/04/16.
//  Copyright © 2016 Dominique d'Argent. All rights reserved.
//

import Foundation

struct Location {
    let latitude: Double
    let longitude: Double
}

class ForecastManager {
    let apiKey: String
    let session: NSURLSession
    
    init(apiKey: String, session: NSURLSession) {
        self.apiKey = apiKey
        self.session = session
    }
    
    func fetch(location: Location, completionHandler: (AnyObject) -> Void) {
        let url = NSURL(string: "https://api.forecast.io/forecast/\(apiKey)/\(location.latitude),\(location.longitude)")!
        let task = session.dataTaskWithURL(url) { (data, response, error) in
            guard error == nil else {
                return
            }
            guard let httpResponse = response as? NSHTTPURLResponse else {
                return
            }
            guard httpResponse.statusCode == 200 else {
                return
            }
            guard let data = data else {
                return
            }
            
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions())
                completionHandler(json)
            }
            catch {
                return
            }
        }
        task.resume()
    }
}
