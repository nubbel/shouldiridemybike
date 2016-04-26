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
    
    init (json: JSON) throws {
        currently = try (json["currently"] as? JSON).flatMap(DataPoint.init).unwrap()
        minutely = try (json["minutely"] as? JSON).flatMap(DataBlock.init)
        hourly = try (json["hourly"] as? JSON).flatMap(DataBlock.init)
        daily = try (json["daily"] as? JSON).flatMap(DataBlock.init)
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

struct DataPoint {
    let time: NSDate
    let icon: Icon?
    let summary: String
    let temperature: Double
    let apparentTemperature: Double
    let precipProbability: Double
    let precipIntensity: Double
    let windSpeed: Double
    
    init(json: JSON) throws {
        time = try (json["time"] as? Double).flatMap(NSDate.init(timeIntervalSince1970:)).unwrap()
        icon = (json["icon"] as? String).flatMap(Icon.init)
        summary = try (json["summary"] as? String).unwrap()
        temperature = try (json["temperature"] as? Double).unwrap()
        apparentTemperature = try (json["apparentTemperature"] as? Double).unwrap()
        precipProbability = try (json["precipProbability"] as? Double).unwrap()
        precipIntensity = try (json["precipIntensity"] as? Double).unwrap()
        windSpeed = try (json["windSpeed"] as? Double).unwrap()
    }
}

struct DataBlock {
    let icon: Icon?
    let summary: String
    let dataPoints: [DataPoint]
    
    init(json: JSON) throws {
        icon = (json["icon"] as? String).flatMap(Icon.init)
        summary = try (json["summary"] as? String).unwrap()
        dataPoints = try (try (json["data"] as? [JSON])?.flatMap(DataPoint.init)).unwrap()
    }
}


private extension Optional {
    func unwrap() throws -> Wrapped {
        if let unwrapped = self {
            return unwrapped
        }
        else {
            throw ForecastError.DecodingFailed
        }
    }
}
