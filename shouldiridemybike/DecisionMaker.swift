//
//  DecisionMaker.swift
//  shouldiridemybike
//
//  Created by Dominique d'Argent on 28/04/16.
//  Copyright © 2016 Dominique d'Argent. All rights reserved.
//

import Foundation

private let numberFormatter: NSNumberFormatter = {
    let formatter = NSNumberFormatter()
    formatter.numberStyle = .DecimalStyle
    formatter.maximumFractionDigits = 2
    
    return formatter
}();

struct DecisionMaker {
    let acceptableTemperatureRange: HalfOpenInterval<Double>
    let maxAcceptablePrecipitationIntensity: Double
    let maxAcceptablePrecipitationProbability: Double
    let maxAcceptablePrecipitationUnconditionalIntensity: Double
    let maxAcceptableWindSpeed: Double
    
    func makeDecision(dataPoint: DataPoint) -> Decision? {
        let temperatureDecision = makeTemperatureDecision(dataPoint)
        let precipitationDecision = makePrecipitationDecision(dataPoint)
        let windSpeedDecision = makeWindSpeedDecision(dataPoint)
        
        let decisions = [temperatureDecision, precipitationDecision, windSpeedDecision].flatMap { $0 }
        
        return decisions.reduce(nil) { (finalDecision, decision) in
            return finalDecision?.merging(decision) ?? decision
        }
    }
    
    func makeTemperatureDecision(dataPoint: DataPoint) -> Decision? {
        guard let temperature = dataPoint.apparentTemperature ?? dataPoint.temperature else {
            return nil
        }
        
        if acceptableTemperatureRange.contains(temperature) {
            return Decision(result: .Yes, reasons: ["Temperature is fine."])
        }
        else {
            let reason: String
            if temperature < acceptableTemperatureRange.start {
                reason = "Temperature too low: \(numberFormatter.stringFromNumber(temperature)!)°C."
            }
            else {
                reason = "Temperature too high: \(numberFormatter.stringFromNumber(temperature)!)°C."
            }
            
            return Decision(result: .No, reasons: [reason])
        }
    }
    
    func makePrecipitationDecision(dataPoint: DataPoint) -> Decision? {
        guard let intensity = dataPoint.precipIntensity, let probability = dataPoint.precipProbability else {
            return nil
        }
        
        let precipType = dataPoint.precipType?.rawValue ?? "precipitation"
        
        if intensity > maxAcceptablePrecipitationIntensity && probability > maxAcceptablePrecipitationProbability {
            let reason = "High chance of \(precipType): \(numberFormatter.stringFromNumber(probability * 100)!)%."
            return Decision(result: .No, reasons: [reason])
        }
        
        if intensity > maxAcceptablePrecipitationUnconditionalIntensity {
            let reason = "Lots of \(precipType)."
            return Decision(result: .No, reasons: [reason])
        }
        
        return Decision(result: .Yes, reasons: ["Weather is fine."])
    }
    
    func makeWindSpeedDecision(dataPoint: DataPoint) -> Decision? {
        guard let windSpeed = dataPoint.windSpeed else {
            return nil
        }
        
        if windSpeed > maxAcceptableWindSpeed {
            let reason = "Too windy: \(numberFormatter.stringFromNumber(windSpeed)) km/h."
            return Decision(result: .No, reasons: [reason])
        }
        
        return Decision(result: .Yes, reasons: ["Not too windy."])
    }
}
