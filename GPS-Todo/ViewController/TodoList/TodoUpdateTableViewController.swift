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
    @IBOutlet weak var stepperEndLocationCount: UIStepper!
    @IBOutlet weak var lblEndLocationCount: UILabel!
    @IBOutlet weak var mapViewEnd: MKMapView!
    
    private let locationManager = GPSLocationManager()
    private var lastLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    private let centerAnnotation = MKPointAnnotation()
    
    // ====== View Model ========= //
    var todoTitle = BehaviorRelay<String>(value: "")
    var content = BehaviorRelay<String>(value: "")
    var endLocationCount = BehaviorRelay<Double>(value: 1.0)
    var endLocations = BehaviorRelay<[CLLocationCoordinate2D]>(value: [])
    
    var startCoord = BehaviorRelay<CLLocationCoordinate2D>(value: CLLocationCoordinate2D())
    
    var isValid: Observable<Bool> {
        return Observable.combineLatest(todoTitle.asObservable(),
                                        content.asObservable(),
                                        startCoord.asObservable()) { title, content, startCoord in
            
            return title.count >= 1 && content.count >= 1
        }
    }
    
    @objc func longPressMapEndLocation(gestureRecognizer: UITapGestureRecognizer) {
        guard mapViewEnd.annotations.count < 5 else {
            return
        }
        
        if gestureRecognizer.state == .began {
            let location = gestureRecognizer.location(in: mapViewEnd)
            let coordinate = mapViewEnd.convert(location, toCoordinateFrom: mapViewEnd)
                
            // Add annotation:
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            mapViewEnd.addAnnotation(annotation)
            annotation.title = "Place \(mapViewEnd.annotations.count)"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(EndLocationCell.self, forCellReuseIdentifier: "TodoUpdate_MapView_EndLoc")
        
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
        
        _ = endLocationCount.asObservable().subscribe(onNext: { [unowned self] endLocationCount in
            lblEndLocationCount.text = "\(Int(endLocationCount))"
            
            let indexSection = IndexSet(SECTION_END_COORDS...SECTION_END_COORDS)
            tableView.reloadSections(indexSection, with: .none)
        })
        
        // _ = stepperEndLocationCount.rx.value.bind(to: endLocationCount)
        
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
        
        //
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
            let coordText = "\(mapViewEnd.annotations[indexPath.row - 2].coordinate)"
            let cell = super.tableView(tableView, cellForRowAt: indexPath)
            if let label = cell.contentView.subviews[0] as? UILabel {
                label.text = coordText
            }
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
        views.forEach { view in
            print(view.annotation?.coordinate)
        }
        
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

class EndLocationCell: UITableViewCell {
    
}
