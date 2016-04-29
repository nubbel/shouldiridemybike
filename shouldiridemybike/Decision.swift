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
        switch result {
        case .Yes:
            return Decision(result: decision.result, reasons: decision.reasons + reasons)
        case .No:
            return Decision(result: result, reasons: reasons + decision.reasons)
        }
    }
}

extension Decision: Equatable {}

func ==(lhs: Decision, rhs: Decision) -> Bool {
    return lhs.result == rhs.result && lhs.reasons == rhs.reasons
}
