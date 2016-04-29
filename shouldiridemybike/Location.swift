//
//  Location.swift
//  shouldiridemybike
//
//  Created by Dominique d'Argent on 26/04/16.
//  Copyright © 2016 Dominique d'Argent. All rights reserved.
//

struct Location {
    let latitude: Double
    let longitude: Double
}

extension Location: Equatable {}

func ==(lhs: Location, rhs: Location) -> Bool {
    return lhs.latitude == rhs.latitude && lhs.longitude == lhs.longitude
}
