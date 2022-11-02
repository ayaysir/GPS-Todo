//
//  TodoUpdateTableViewController.swift
//  GPS-Todo
//
//  Created by yoonbumtae on 2022/10/30.
//

import UIKit
import MapKit
import RxSwift
import RxRelay
import BGSMM_DevKit

class TodoUpdateTableViewController: UITableViewController {
    
    private let SECTION_END_COORDS = 3
    
    @IBOutlet weak var txfTitle: UITextField!
    @IBOutlet weak var txvContent: UITextView!
    @IBOutlet weak var mapViewStart: MKMapView!
    @IBOutlet weak var barBtnSubmit: UIBarButtonItem!
    @IBOutlet weak var mapViewEnd: MKMapView!
    @IBOutlet weak var btnRemoveAnnotation: UIButton!
    
    private let locationManager = GPSLocationManager()
    private var lastLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    private let centerAnnotation = MKPointAnnotation()
    
    private var sortedAnnotations: [MKAnnotation] {
        return mapViewEnd.annotations.sorted { anot1, anot2 in
            guard let anot1Title = anot1.title ?? "a",
                  let anot2Title = anot2.title ?? "b" else {
                return false
            }
        
            return anot1Title < anot2Title
        }
    }
    private var placeCount: Int = 1
    
    // ====== View Model ========= //
    var todoTitle = BehaviorRelay<String>(value: "")
    var content = BehaviorRelay<String>(value: "")
    
    var startCoord = BehaviorRelay<CLLocationCoordinate2D>(value: CLLocationCoordinate2D())
    var endAnnotations = BehaviorRelay<[MKAnnotation]>(value: [])
    
    var isValid: Observable<Bool> {
        return Observable.combineLatest(todoTitle.asObservable(),
                                        content.asObservable(),
                                        startCoord.asObservable()) { title, content, startCoord in
            
            return title.count >= 1 && content.count >= 1
        }
    }
    
    @objc func longPressMapEndLocation(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            guard mapViewEnd.annotations.count < 5 else {
                SimpleAlert.presentCaution(message: "5개까지만 추가가능")
                return
            }
            
            let location = gestureRecognizer.location(in: mapViewEnd)
            let coordinate = mapViewEnd.convert(location, toCoordinateFrom: mapViewEnd)
            
            // Add annotation:
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "Place \(placeCount)"
            placeCount += 1
            mapViewEnd.addAnnotation(annotation)
            
            // https://developer.apple.com/forums/thread/126473
            self.mapViewEnd.setCenter(coordinate, animated: true)
        }
    }
    
    @objc func longPressAnnotation(_ gestureRecognizer: UILongPressGestureRecognizer) {
        let selected = mapViewEnd.selectedAnnotations
        mapViewEnd.removeAnnotations(selected)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nib = UINib(nibName: "EndLocationTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "EndLocation_XIB")

        // mapView start
        mapViewStart.delegate = self
        mapViewStart.setZoomByDelta(delta: pow(2, -13), animated: true)
        mapViewStart.isScrollEnabled = false
        centerAnnotation.title = "Current Location"
        mapViewStart.addAnnotation(centerAnnotation)
        
        // mapView End
        mapViewEnd.delegate = self
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressMapEndLocation))
        mapViewEnd.addGestureRecognizer(longPressGesture)
        
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
        
        
        
        _ = Observable
            .of(mapViewEnd.annotations)
            .map({ $0 })
            .subscribe(onNext: { annots in
            print("Annots:", annots)
        })
        
        _ = txfTitle.rx.text.map({ $0 ?? ""}).bind(to: todoTitle)
        _ = txvContent.rx.text.map({ $0 ?? ""}).bind(to: content)
        
        _ = isValid.subscribe(onNext: { [unowned self] isValid in
            barBtnSubmit.isEnabled = isValid
        })
        
        // Submit to Firebase - barBtn Clicked
        _ = barBtnSubmit.rx.tap.subscribe(onNext: { [unowned self] in
            print(todoTitle.value, content.value, startCoord.value)
            
            let endCoords = mapViewEnd.annotations.map { "\($0.coordinate)" }
            let todo = Todo(title: todoTitle.value,
                            content: content.value,
                            startCoord: "\(startCoord.value)",
                            endCoords: endCoords)
            print("To Update Todo:", todo)
            
            FirestoreTodo.shared.addPost(todoRequest: todo) { documenID in
                SimpleAlert.present(message: "Success", title: "Add Todo") { _ in
                    self.navigationController?.popViewController(animated: true)
                }
            }
        })
        
        // btnRemoveAnnotation
        _ = btnRemoveAnnotation.rx.tap.subscribe(onNext: { [unowned self] in
            if mapViewEnd.selectedAnnotations.count > 0 {
                mapViewEnd.removeAnnotations(mapViewEnd.selectedAnnotations)
                tableView.reloadData()
            }
        })
    }
}

extension TodoUpdateTableViewController {
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == SECTION_END_COORDS {
            return Int(2 + mapViewEnd.annotations.count)
        }
        
        return super.tableView(tableView, numberOfRowsInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == SECTION_END_COORDS && indexPath.row >= 2 {
            // let coordText = "\(mapViewEnd.annotations[indexPath.row - 2].coordinate)"
            // let cell = super.tableView(tableView, cellForRowAt: indexPath)
            // if let label = cell.contentView.subviews[0] as? UILabel {
            //     label.text = coordText
            // }
            
            // return EndLocationCell(frame: cell.frame)
            
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "EndLocation_XIB", for: indexPath) as? EndLocationTableViewCell else {
                return UITableViewCell()
            }
            
            cell.selectionStyle = .none
            
            // TODO: 좌표 소수점 표시 > extension으로 빼기
            // let annotation = mapViewEnd.annotations[indexPath.row - 2]
            let annotation = sortedAnnotations[indexPath.row - 2]
            cell.configure(annotation: annotation)
            cell.delegate = self
            
            return cell
        }
        
        return super.tableView(tableView, cellForRowAt: indexPath)
    }
}

extension TodoUpdateTableViewController: MKMapViewDelegate {
    
    // MARK: - MapView Delegate
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        print(#function)
    }
    
    func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
        print(#function)
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        
        switch mapView {
        case mapViewStart:
            let zoomWidth = mapView.visibleMapRect.size.width
            let zoomFactor = Int(log2(zoomWidth)) - 9
            startCoord.accept(mapView.centerCoordinate)
        case mapViewEnd:
            break
        default:
            break
        }
        
        // print(#function)
        // print("...REGION DID CHANGE: ZOOM FACTOR \(zoomFactor)")
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState) {
        print(#function)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let coordinate =  view.annotation?.coordinate,
           mapView == mapViewEnd {
            print(coordinate)
        }
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        tableView.reloadData()
    }
}

extension TodoUpdateTableViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate,
              lastLocation.latitude != locValue.latitude || lastLocation.longitude != locValue.longitude
        else {
            return
        }
        
        centerAnnotation.coordinate = locValue
        mapViewStart.centerCoordinate = locValue
    }
}

extension TodoUpdateTableViewController: EndLocationTVCellDelegate {
    func didDeleteButtonClicked(_ cell: EndLocationTableViewCell) {
        guard let annotation = cell.annotation else {
            return
        }
        
        mapViewEnd.removeAnnotation(annotation)
        tableView.reloadData()
    }
}
