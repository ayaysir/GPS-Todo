//
//  TodoDetailTableViewController.swift
//  GPS-Todo
//
//  Created by yoonbumtae on 2022/10/29.
//

import UIKit
import MapKit

class TodoDetailTableViewController: UITableViewController {

    private let locationManager = CLLocationManager()
    
    @IBOutlet weak var mainMap: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // "물왕저수지 정통밥집" 선택 - 핀을 설치하고 위치 정보 표시
        setAnnotation(latitudeValue: 37.3826616, longitudeValue: 126.840719, delta: 0.1, title: "물왕저수지 정통밥집", subtitle: "경기 시흥시 동서로857번길 6")
    }
    
    // MARK: - Table view data source


}

extension TodoDetailTableViewController: CLLocationManagerDelegate {
    // 위도와 경도, 스팬(영역 폭)을 입력받아 지도에 표시
     func goLocation(latitudeValue: CLLocationDegrees,
                     longtudeValue: CLLocationDegrees,
                     delta span: Double) -> CLLocationCoordinate2D {
         let pLocation = CLLocationCoordinate2DMake(latitudeValue, longtudeValue)
         let spanValue = MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
         let pRegion = MKCoordinateRegion(center: pLocation, span: spanValue)
         mainMap.setRegion(pRegion, animated: true)
         return pLocation
     }
     
     // 특정 위도와 경도에 핀 설치하고 핀에 타이틀과 서브 타이틀의 문자열 표시
     func setAnnotation(latitudeValue: CLLocationDegrees,
                        longitudeValue: CLLocationDegrees,
                        delta span :Double,
                        title strTitle: String,
                        subtitle strSubTitle:String){
         let annotation = MKPointAnnotation()
         annotation.coordinate = goLocation(latitudeValue: latitudeValue, longtudeValue: longitudeValue, delta: span)
         annotation.title = strTitle
         annotation.subtitle = strSubTitle
         mainMap.addAnnotation(annotation)
     }
     
     // 위치 정보에서 국가, 지역, 도로를 추출하여 레이블에 표시
     func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
         let pLocation = locations.last
         _ = goLocation(latitudeValue: (pLocation?.coordinate.latitude)!,
                    longtudeValue: (pLocation?.coordinate.longitude)!,
                    delta: 0.01)
         CLGeocoder().reverseGeocodeLocation(pLocation!, completionHandler: {(placemarks, error) -> Void in
             let pm = placemarks!.first
             let country = pm!.country
             var address: String = ""
             if country != nil {
                 address = country!
             }
             if pm!.locality != nil {
                 address += " "
                 address += pm!.locality!
             }
             if pm!.thoroughfare != nil {
                 address += " "
                 address += pm!.thoroughfare!
             }
             print("address:", address)
         })
         locationManager.stopUpdatingLocation()
     }
}
