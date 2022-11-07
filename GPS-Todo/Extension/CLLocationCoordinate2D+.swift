//
//  CLLocationCoordinate2D+.swift
//  GPS-Todo
//
//  Created by yoonbumtae on 2022/11/07.
//

import Foundation
import CoreLocation

extension CLLocationCoordinate2D {
    
    /// Returns the distance (measured in meters) from the current object’s location to the specified location.
    func distance(from location: CLLocationCoordinate2D) -> CLLocationDistance {
        let locTo = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let locFrom = CLLocation(latitude: location.latitude, longitude: location.longitude)
        return locTo.distance(from: locFrom)
    }
}
