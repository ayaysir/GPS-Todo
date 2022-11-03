//
//  TodoDetailTableViewController.swift
//  GPS-Todo
//
//  Created by yoonbumtae on 2022/10/29.
//

import UIKit
import MapKit
import RxSwift

class TodoDetailTableViewController: UITableViewController {
    
    private let SECTION_END_LOCATION = 4

    private let locationManager = GPSLocationManager()
    private let disposeBag = DisposeBag()
    
    @IBOutlet weak var mainMap: MKMapView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var txvContent: UITextView!
    @IBOutlet weak var lblStartCoord: UILabel!
    @IBOutlet weak var segEndLocation: UISegmentedControl!
    
    var todo: Todo!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nib = UINib(nibName: "EndLocationTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "EndLocation_XIB")
        
        // RxSwift
        _ = segEndLocation.rx.selectedSegmentIndex.subscribe(onNext: { [unowned self] index in
            let centerCoord = todo.endCoords[index].toCLCoordinate()
            mainMap.setCenter(centerCoord, animated: true)
        }).disposed(by: disposeBag)
        
        // 임시: 내용 표시
        lblTitle.text = todo.title
        txvContent.text = todo.content
        lblStartCoord.text = "\(todo.startCoord)"
        
        tableView.reloadData()
        // "물왕저수지 정통밥집" 선택 - 핀을 설치하고 위치 정보 표시
        todo.endCoords.forEach { [unowned self] info in
            setAnnotation(latitudeValue: info.latitude,
                          longitudeValue: info.longitude,
                          delta: 0.5,
                          title: info.title ?? "물왕저수지 정통밥집",
                          subtitle: info.subtitle ?? "경기 시흥시 동서로857번길 6"
            )
        }
        
        let endCoordsCount = todo.endCoords.count
        if endCoordsCount > 1 {
            let segStrings = todo.endCoords.enumerated().map { (index, coord) in
                coord.title ?? "Place \(index + 1)"
            }
            segEndLocation.replaceSegments(segments: segStrings)
            segEndLocation.selectedSegmentIndex = 0
            segEndLocation.isHidden = false
        } else {
            segEndLocation.isHidden = true
        }
    }
    
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == SECTION_END_LOCATION && indexPath.row > 0 {
            guard let cell =  tableView.dequeueReusableCell(withIdentifier: "EndLocation_XIB", for: indexPath) as? EndLocationTableViewCell else {
                return super.tableView(tableView, cellForRowAt: indexPath)
            }
            
            cell.selectionStyle = .none
            cell.configure(annotation: mainMap.annotations[indexPath.row - 1])
            return cell
        }
        
        return super.tableView(tableView, cellForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == SECTION_END_LOCATION {
            return 1 + todo.endCoords.count
        }
        
        return super.tableView(tableView, numberOfRowsInSection: section)
    }

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
