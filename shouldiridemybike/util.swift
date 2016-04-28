//
//  util.swift
//  shouldiridemybike
//
//  Created by Dominique d'Argent on 28/04/16.
//  Copyright © 2016 Dominique d'Argent. All rights reserved.
//

import Foundation

func configure<T : AnyObject>(object: T, configuration: T -> Void) -> T {
    configuration(object)
    
    return object
}