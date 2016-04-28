//
//  State.swift
//  shouldiridemybike
//
//  Created by Dominique d'Argent on 28/04/16.
//  Copyright © 2016 Dominique d'Argent. All rights reserved.
//

import Foundation


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

enum Action {
    case RequestPermissionFromUser
    case Retry
}