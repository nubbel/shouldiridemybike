//
//  ForecastManager.swift
//  shouldiridemybike
//
//  Created by Dominique d'Argent on 24/04/16.
//  Copyright © 2016 Dominique d'Argent. All rights reserved.
//

import Foundation


enum ForecastError: ErrorType {
    case InvalidResponse
    case InvalidJSON
}

class ForecastManager {
    let apiKey: String
    let session: NSURLSession
    
    init(apiKey: String, session: NSURLSession) {
        self.apiKey = apiKey
        self.session = session
    }
    
    func fetch(location: Location, completionHandler: (Forecast!, ErrorType?) -> Void) {
        let language = NSBundle.mainBundle().preferredLocalizations.first!
        let url = NSURL(string: "https://api.forecast.io/forecast/\(apiKey)/\(location.latitude),\(location.longitude)?units=si&exclude=minutely,daily,alerts,flags&lang=\(language)")!
        let task = session.dataTaskWithURL(url) { (data, response, error) in
            do {
                if let error = error {
                    throw error
                }
                
                guard let jsonData = data,
                    let httpResponse = response as? NSHTTPURLResponse where httpResponse.statusCode == 200 else {
                        throw ForecastError.InvalidResponse
                }
                
                let json = try NSJSONSerialization.JSONObjectWithData(jsonData, options: [])
                
                guard let forecast = (json as? JSON).flatMap(Forecast.init) else {
                    throw ForecastError.InvalidJSON
                }
                
                completionHandler(forecast, nil)
            }
            catch let error {
                completionHandler(nil, error)
            }
        }
        task.resume()
    }
}
