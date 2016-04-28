//
//  Decision.swift
//  shouldiridemybike
//
//  Created by Dominique d'Argent on 28/04/16.
//  Copyright © 2016 Dominique d'Argent. All rights reserved.
//

import Foundation

struct Decision {
    enum Result {
        case Yes, No
    }
    
    let result: Result
    let reasons: [String]
    
    var reason: String {
        return reasons.joinWithSeparator(" ")
    }
    
    func merging(decision: Decision) -> Decision {
        let mergedReasons = reasons + decision.reasons
        
        switch result {
        case .Yes:
            return Decision(result: decision.result, reasons: mergedReasons)
        case .No:
            return Decision(result: result, reasons: mergedReasons)
        }
    }
}
