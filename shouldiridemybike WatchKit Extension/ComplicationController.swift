//
//  ComplicationController.swift
//  shouldiridemybike WatchKit Extension
//
//  Created by Dominique d'Argent on 24/04/16.
//  Copyright © 2016 Dominique d'Argent. All rights reserved.
//

import ClockKit
import WatchConnectivity

class ComplicationController: NSObject, CLKComplicationDataSource {
    struct DecisionDataPoint {
        let time: NSDate
        let decision: String
        let reasons: [String]
    }

    let session: WCSession
    let complicationServer: CLKComplicationServer
    
    var timelineData: [DecisionDataPoint] = []
    var lastUpdate: NSDate?
    
    override init() {
        session = WCSession.defaultSession()
        complicationServer = CLKComplicationServer.sharedInstance()
        
        super.init()
        
        session.delegate = self
        session.activateSession()
    }
    
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirectionsForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTimeTravelDirections) -> Void) {
        handler([.Forward])
    }
    
    func getTimelineStartDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        handler(timelineData.first?.time)
    }
    
    func getTimelineEndDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        handler(timelineData.last?.time)
    }
    
    func getPrivacyBehaviorForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.ShowOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntryForComplication(complication: CLKComplication, withHandler handler: ((CLKComplicationTimelineEntry?) -> Void)) {
        guard let current = timelineData.first else {
            handler(nil)
            return
        }
        
        // Call the handler with the current timeline entry
        handler(buildTimelineEntryForComplication(complication, decisionDataPoint: current))
    }
    
    func getTimelineEntriesForComplication(complication: CLKComplication, beforeDate date: NSDate, limit: Int, withHandler handler: (([CLKComplicationTimelineEntry]?) -> Void)) {
        var entries = [CLKComplicationTimelineEntry]()
        var count = 0
        
        for dataPoint in timelineData where dataPoint.time.compare(date) == .OrderedAscending && count < limit {
            if let entry = buildTimelineEntryForComplication(complication, decisionDataPoint: dataPoint) {
                entries.append(entry)
                count += 1
            }
        }
        
        // Call the handler with the timeline entries prior to the given date
        handler(entries)
    }
    
    func getTimelineEntriesForComplication(complication: CLKComplication, afterDate date: NSDate, limit: Int, withHandler handler: (([CLKComplicationTimelineEntry]?) -> Void)) {
        var entries = [CLKComplicationTimelineEntry]()
        var count = 0
        
        for dataPoint in timelineData where dataPoint.time.compare(date) == .OrderedDescending && count < limit {
            if let entry = buildTimelineEntryForComplication(complication, decisionDataPoint: dataPoint) {
                entries.append(entry)
                count += 1
            }
        }
        
        // Call the handler with the timeline entries after to the given date
        handler(entries)
    }
    
    // MARK: - Update Scheduling
    
    func getNextRequestedUpdateDateWithHandler(handler: (NSDate?) -> Void) {
        // Call the handler with the date when you would next like to be given the opportunity to update your complication content
        handler(nil);
    }
    
    // MARK: - Placeholder Templates
    
    func getPlaceholderTemplateForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
        
        let textProvider = CLKSimpleTextProvider(text: "Should I ride my bike?", shortText: "Bike?")
        
        switch complication.family {
        case .ModularSmall:
            let template = CLKComplicationTemplateModularSmallSimpleImage()
            template.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "bike_modular_small")!)
            handler(template)
        case .ModularLarge:
            let template = CLKComplicationTemplateModularLargeStandardBody()
            template.headerImageProvider = CLKImageProvider(onePieceImage: UIImage(named: "bike_modular_large")!)
            template.headerTextProvider = textProvider
            template.body1TextProvider = textProvider
            handler(template)
        default:
            break
        }
        
        handler(nil)
    }
    
}

extension ComplicationController: WCSessionDelegate {
    
    func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        guard let time = userInfo["time"] as? NSDate, let data = userInfo["data"] as? [[String: AnyObject]] else {
            return
        }
        
        if lastUpdate == nil || lastUpdate!.compare(time) == .OrderedAscending {
            timelineData = data.flatMap { dataPoint in
                guard let time = dataPoint["time"] as? NSDate,
                    let decision = dataPoint["decision"] as? String,
                    let reasons = dataPoint["reasons"] as? [String]
                else {
                        return nil
                }
                
                return DecisionDataPoint(time: time, decision: decision, reasons: reasons)
            }
            lastUpdate = time
            
            reloadComplications()
        }
    }
}

private extension ComplicationController {
    func buildTimelineEntryForComplication(complication: CLKComplication, decisionDataPoint: DecisionDataPoint) -> CLKComplicationTimelineEntry? {
        guard let template = buildTemplateForComplication(complication, decisionDataPoint: decisionDataPoint) else {
            return nil
        }
        
        return CLKComplicationTimelineEntry(date: decisionDataPoint.time, complicationTemplate: template)
    }
    
    func buildTemplateForComplication(complication: CLKComplication, decisionDataPoint: DecisionDataPoint) -> CLKComplicationTemplate? {
        let headerTextProvider = CLKSimpleTextProvider(text: decisionDataPoint.decision)
        let bodyTextProvider = CLKSimpleTextProvider(text: decisionDataPoint.reasons.joinWithSeparator(" "))
        
        switch complication.family {
        case .ModularSmall:
            let template = CLKComplicationTemplateModularSmallStackImage()
            template.line1ImageProvider = CLKImageProvider(onePieceImage: UIImage(named: "bike_modular_small_stacked")!)
            template.line2TextProvider = headerTextProvider
            
            return template
        case .ModularLarge:
            let template = CLKComplicationTemplateModularLargeStandardBody()
            template.headerImageProvider = CLKImageProvider(onePieceImage: UIImage(named: "bike_modular_large")!)
            template.headerTextProvider = headerTextProvider
            template.body1TextProvider = bodyTextProvider
            return template
        default:
            
            return nil
        }
    }
    
    func reloadComplications() {
        if let complications: [CLKComplication] = CLKComplicationServer.sharedInstance().activeComplications {
            for complication in complications {
                complicationServer.reloadTimelineForComplication(complication)
                NSLog("Reloading complication \(complication.description)...")
            }
        }
    }
}
