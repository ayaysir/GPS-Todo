//
//  CoordInfo.swift
//  GPS-Todo
//
//  Created by yoonbumtae on 2022/11/03.
//

import MapKit

struct CoordInfo: Codable {
    var latitude: Double
    var longitude: Double
    var title: String?
    var subtitle: String?
    
    init(fromCoord coord: CLLocationCoordinate2D) {
        self.latitude = coord.latitude
        self.longitude = coord.longitude
    }
    
    init(fromAnnotation annotation: MKAnnotation) {
        self.latitude = annotation.coordinate.latitude
        self.longitude = annotation.coordinate.longitude
        self.title = annotation.title!
        self.subtitle = annotation.subtitle!
    }
    
    func toCLCoordinate() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
