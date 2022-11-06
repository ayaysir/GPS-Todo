//
//  GPSLocationManager.swift
//  GPS-Todo
//
//  Created by yoonbumtae on 2022/11/01.
//

import CoreLocation

class GPSLocationManager: CLLocationManager {
    
    var authStatus: CLAuthorizationStatus {
        if #available(iOS 14, *) {
            return self.authorizationStatus
        } else {
            return CLLocationManager.authorizationStatus()
        }
    }
    
    override init() {
        super.init()
        
        self.requestAlwaysAuthorization()
        self.requestWhenInUseAuthorization()
        
        var locationAuthStatus: CLAuthorizationStatus {
            if #available(iOS 14, *) {
                return self.authorizationStatus
            } else {
                return CLLocationManager.authorizationStatus()
            }
        }
    }
    
    func instantStartUpdatingLocation(delegateTo controller: CLLocationManagerDelegate?) {
        if let controller = controller {
            self.delegate = controller
        }
        self.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        self.startUpdatingLocation()
    }
}
