//
//  TodoDetailTableViewController.swift
//  GPS-Todo
//
//  Created by yoonbumtae on 2022/10/29.
//

import UIKit
import MapKit
import RxSwift
import RxCocoa
import BGSMM_DevKit

class TodoDetailTableViewController: UITableViewController {
    
    private let SECTION_END_LOCATION = 4

    private let locationManager = GPSLocationManager()
    private let disposeBag = DisposeBag()
    
    @IBOutlet weak var mainMap: MKMapView!
    @IBOutlet weak var txfTitle: UITextField!
    @IBOutlet weak var txvContent: UITextView!
    @IBOutlet weak var lblStartCoord: UILabel!
    @IBOutlet weak var segEndLocation: UISegmentedControl!
    @IBOutlet weak var barBtnUpdate: UIBarButtonItem!
    @IBOutlet weak var lblScheduleStatus: UILabel!
    @IBOutlet weak var btnCheck: UIButton!
    
    private var overlayOnTxfTitle: UIView!
    
    private var currentLocationAnnotation: MKPointAnnotation!
    
    var todo: Todo!
    
    // === VIEW MODEL == //
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nib = UINib(nibName: "EndLocationTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "EndLocation_XIB")
        
        let outsideTapGesture = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        tableView.addGestureRecognizer(outsideTapGesture)
        
        currentLocationAnnotation = MKPointAnnotation()
        currentLocationAnnotation.title = "Current"
        currentLocationAnnotation.subtitle = "Current Location ()"
        mainMap.addAnnotation(currentLocationAnnotation)
        
        switch locationManager.authStatus {
        case .notDetermined, .authorizedAlways, .authorizedWhenInUse:
            locationManager.instantStartUpdatingLocation(delegateTo: self)
        case .restricted:
            break
        case .denied:
            break
        @unknown default:
            break
        }
        
        // Init
        lblScheduleStatus.text = todo.scheduleType.textValue(todo.schedulePerDay)
        
        // RxSwift
        _ = segEndLocation.rx.selectedSegmentIndex.subscribe(onNext: { [unowned self] index in
            let centerCoord = todo.endCoords[index].toCLCoordinate()
            mainMap.setCenter(centerCoord, animated: true)
        }).disposed(by: disposeBag)
        
        _ = barBtnUpdate.rx.tap.subscribe { _ in
        }.disposed(by: disposeBag)
        
        let doubleTapGestureOnTextView = UITapGestureRecognizer(target: self, action: #selector(doubleTapFields))
        doubleTapGestureOnTextView.numberOfTapsRequired = 2
        
        let doubleTapGestureOnTextField = UITapGestureRecognizer(target: self, action: #selector(doubleTapFields))
        doubleTapGestureOnTextField.numberOfTapsRequired = 2
        
        txvContent.addGestureRecognizer(doubleTapGestureOnTextView)
        
        // DidEndEditing - Text View
        _ = txvContent.rx.didEndEditing.subscribe { [unowned self] _ in
            txvContent.isEditable = false
            
            // update to firestore
            guard let documentID = todo.documentID else {
                return
            }
            todo.content = txvContent.text
            FirestoreTodo.shared.updateTodo(documentID: documentID, originalTodoRequest: todo) { documentId in
                
            }
        }.disposed(by: disposeBag)
        
        overlayOnTxfTitle = UIView(frame: self.txfTitle.frame)
        overlayOnTxfTitle.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0)
        txfTitle.superview?.addSubview(overlayOnTxfTitle)
        overlayOnTxfTitle.addGestureRecognizer(doubleTapGestureOnTextField)
        
        // DidEndEditing - Text Field
        _ = txfTitle.rx.controlEvent([.editingDidEnd]).asObservable().subscribe { [unowned self]  _ in
            txfTitle.isEnabled = false
            overlayOnTxfTitle.isHidden = false
            
            // update to firestore
            guard let documentID = todo.documentID,
                  let titleText = txfTitle.text else {
                return
            }
            todo.title = titleText
            FirestoreTodo.shared.updateTodo(documentID: documentID, originalTodoRequest: todo) { documentId in
                
            }
        }.disposed(by: disposeBag)
        
        // 임시: 내용 표시
        txfTitle.text = todo.title
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
        if endCoordsCount >= 1 {
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
    
    @objc func endEditing() {
    }
    
    @objc func doubleTapFields(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view else {
            return
        }
        
        switch view {
        case overlayOnTxfTitle:
            print("txfTitle")
            if !txfTitle.isEnabled {
                overlayOnTxfTitle.isHidden = true
                txfTitle.isEnabled = true
                txfTitle.becomeFirstResponder()
            } else {
                return
            }
        case txvContent:
            if !txvContent.isEditable {
                txvContent.isEditable = true
                txvContent.becomeFirstResponder()
            } else {
                return
            }
        default:
            break
        }
        
    }
    
    
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == SECTION_END_LOCATION && indexPath.row > 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "EndLocation_XIB", for: indexPath) as? EndLocationTableViewCell else {
                return super.tableView(tableView, cellForRowAt: indexPath)
            }
            
            cell.selectionStyle = .none
            cell.buttonMode = .placeIcon
            // cell.configure(annotation: mainMap.annotations[indexPath.row - 1])
            cell.configure(info: todo.endCoords[indexPath.row - 1], indexPath: indexPath)
            cell.delegate = self
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(#function, indexPath)
        if indexPath.section == SECTION_END_LOCATION && indexPath.row > 0 {
            let coordinate = mainMap.annotations[indexPath.row - 1].coordinate
            mainMap.setCenter(coordinate, animated: true)
        }
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
                        delta span: Double,
                        title strTitle: String,
                        subtitle strSubTitle: String){
         let annotation = MKPointAnnotation()
         annotation.coordinate = goLocation(latitudeValue: latitudeValue, longtudeValue: longitudeValue, delta: span)
         annotation.title = strTitle
         annotation.subtitle = strSubTitle
         mainMap.addAnnotation(annotation)
     }
     
     // 위치 정보에서 국가, 지역, 도로를 추출하여 레이블에 표시
     func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
         // let pLocation = locations.last
         // _ = goLocation(latitudeValue: (pLocation?.coordinate.latitude)!,
         //            longtudeValue: (pLocation?.coordinate.longitude)!,
         //            delta: 0.01)
         // CLGeocoder().reverseGeocodeLocation(pLocation!, completionHandler: {(placemarks, error) -> Void in
         //     let pm = placemarks!.first
         //     let country = pm!.country
         //     var address: String = ""
         //     if country != nil {
         //         address = country!
         //     }
         //     if pm!.locality != nil {
         //         address += " "
         //         address += pm!.locality!
         //     }
         //     if pm!.thoroughfare != nil {
         //         address += " "
         //         address += pm!.thoroughfare!
         //     }
         //     print("address:", address)
         // })
         // locationManager.stopUpdatingLocation()
         
         // 현재 위치 업데이트
         guard let currLocCoord: CLLocationCoordinate2D = manager.location?.coordinate
         else {
             return
         }
         // print(#function, currLocCoord)
         currentLocationAnnotation.coordinate = currLocCoord
         currentLocationAnnotation.subtitle = "At (\(currLocCoord.latitude), \(currLocCoord.longitude))"
         // mainMap.setCenter(currLocCoord, animated: true)
         
         btnCheck.isEnabled = false
         
         todo.endCoords.forEach { info in
             let distance = currLocCoord.distance(from: info.toCLCoordinate())
             print(info.title, distance)
             if distance <= 5 {
                 btnCheck.isEnabled = true
             }
         }
         
     }
}

extension TodoDetailTableViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // Check for type here, not for the Title!!!
        if false {
            let identifier = "Identifier for this annotation"
            let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView.image = UIImage(systemName: "chart.pie.fill")
            annotationView.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
            
            annotationView.canShowCallout = false
            return annotationView
        }
     
        return nil
    }
}

extension TodoDetailTableViewController: UIGestureRecognizerDelegate {

}

extension TodoDetailTableViewController: EndLocationTVCellDelegate {
    func didIconButtonClicked(_ cell: EndLocationTableViewCell) {
        
    }
    
    func didEntireCellClicked(_ cell: EndLocationTableViewCell) {
        guard let indexPath = cell.indexPath else {
            return
        }
        
        let row = indexPath.row - 1
        
        let target = todo.endCoords[row]
        mainMap.setCenter(target.toCLCoordinate(), animated: true)
    }
}
