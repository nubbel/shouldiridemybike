//
//  Forecast.swift
//  shouldiridemybike
//
//  Created by Dominique d'Argent on 26/04/16.
//  Copyright © 2016 Dominique d'Argent. All rights reserved.
//

import Foundation


struct Forecast {
    let currently: DataPoint
    let minutely: DataBlock?
    let hourly: DataBlock?
    let daily: DataBlock?
    
    var timeline: [DataPoint] {
        var dataPoints = [currently];
        dataPoints.appendContentsOf(minutely?.dataPoints ?? [])
        dataPoints.appendContentsOf(hourly?.dataPoints ?? [])
        dataPoints.appendContentsOf(daily?.dataPoints ?? [])
        
        return dataPoints;
    }
    
    init?(json: JSON) {
        guard let currently = (json["currently"] as? JSON).flatMap(DataPoint.init) else {
            return nil
        }
        self.currently = currently
        
        minutely = (json["minutely"] as? JSON).flatMap(DataBlock.init)
        hourly = (json["hourly"] as? JSON).flatMap(DataBlock.init)
        daily = (json["daily"] as? JSON).flatMap(DataBlock.init)
    }
}

enum Icon: String {
    case ClearDay = "clear-day"
    case ClearNight = "clear-night"
    case Rain = "rain"
    case Snow = "snow"
    case Sleet = "sleet"
    case Wind = "wind"
    case Fog = "fog"
    case Cloudy = "cloudy"
    case PartlyCloudyDay = "partly-cloudy-day"
    case PartlyCloudyNight = "partly-cloudy-night"
}

enum Precipitation: String {
    case Rain = "rain"
    case Snow = "snow"
    case Sleet = "sleet"
    case Hail = "hail"
}

struct DataPoint {
    let time: NSDate
    let icon: Icon?
    let summary: String?
    let temperature: Double?
    let apparentTemperature: Double?
    let precipProbability: Double?
    let precipIntensity: Double?
    let precipType: Precipitation?
    let windSpeed: Double?
    
    init?(json: JSON) {
        guard let time = (json["time"] as? Double).flatMap(NSDate.init(timeIntervalSince1970:)) else {
            return nil
        }
        self.time = time
        
        icon = (json["icon"] as? String).flatMap(Icon.init)
        summary = json["summary"] as? String
        temperature = json["temperature"] as? Double
        apparentTemperature = json["apparentTemperature"] as? Double
        precipProbability = json["precipProbability"] as? Double
        precipIntensity = json["precipIntensity"] as? Double
        precipType = (json["precipType"] as? String).flatMap(Precipitation.init)
        windSpeed = json["windSpeed"] as? Double
    }
 
}

struct DataBlock {
    let dataPoints: [DataPoint]
    let icon: Icon?
    let summary: String?
    
    init?(json: JSON) {
        guard let dataPoints = (json["data"] as? [JSON])?.flatMap(DataPoint.init) else {
            return nil
        }
        self.dataPoints = dataPoints
        
        icon = (json["icon"] as? String).flatMap(Icon.init)
        summary = json["summary"] as? String
    }
}
