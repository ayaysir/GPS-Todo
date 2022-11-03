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
    
    // MARK: - Constants
    
    private let SECTION_END_COORDS = 3
    
    // MARK: - @IBOutlet
    
    @IBOutlet weak var txfTitle: UITextField!
    @IBOutlet weak var txvContent: UITextView!
    @IBOutlet weak var mapViewStart: MKMapView!
    @IBOutlet weak var barBtnSubmit: UIBarButtonItem!
    @IBOutlet weak var mapViewEnd: MKMapView!
    @IBOutlet weak var btnRemoveAnnotation: UIButton!
    
    // MARK: - Member variables
    
    private let viewModel = TodoUpdateViewModel()
    private let disposeBag = DisposeBag()
    
    private let locationManager = GPSLocationManager()
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
    
    //MARK: - Life cycle
    
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
        
        // ======= RxSwift =======
        
        _ = txfTitle.rx.text.map({ $0 ?? ""}).bind(to: viewModel.todoTitle)
        _ = txvContent.rx.text.map({ $0 ?? ""}).bind(to: viewModel.content)
        
        _ = viewModel.isValid.subscribe(onNext: { [unowned self] isValid in
            barBtnSubmit.isEnabled = isValid
        }).disposed(by: disposeBag)
        
        // Submit to Firebase - barBtn Clicked
        _ = barBtnSubmit.rx.tap.subscribe(onNext: { [unowned self] in
            let endCoords = mapViewEnd.annotations.map { CoordInfo(fromAnnotation: $0) }
            let todo = Todo(title: viewModel.todoTitle.value,
                            content: viewModel.content.value,
                            startCoord: CoordInfo(fromCoord: viewModel.startCoord.value),
                            endCoords: endCoords)
            print("To Update Todo:", todo)
            
            FirestoreTodo.shared.addPost(todoRequest: todo) { documenID in
                SimpleAlert.present(message: "Success", title: "Add Todo") { _ in
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }).disposed(by: disposeBag)
        
        // btnRemoveAnnotation
        _ = btnRemoveAnnotation.rx.tap.subscribe(onNext: { [unowned self] in
            if mapViewEnd.selectedAnnotations.count > 0 {
                mapViewEnd.removeAnnotations(mapViewEnd.selectedAnnotations)
                tableView.reloadData()
            }
        }).disposed(by: disposeBag)
    }
    
    // MARK: - @objc methods
    
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
}

extension TodoUpdateTableViewController {
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == SECTION_END_COORDS {
            return Int(2 + mapViewEnd.annotations.count)
        }
        
        return super.tableView(tableView, numberOfRowsInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == SECTION_END_COORDS && indexPath.row >= 2 {
            
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "EndLocation_XIB", for: indexPath) as? EndLocationTableViewCell else {
                return UITableViewCell()
            }
            
            cell.selectionStyle = .none
            
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
            let _ = Int(log2(zoomWidth)) - 9
            viewModel.startCoord.accept(mapView.centerCoordinate)
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
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate
        else {
            return
        }
        
        centerAnnotation.coordinate = locValue
        mapViewStart.centerCoordinate = locValue
    }
}

extension TodoUpdateTableViewController: EndLocationTVCellDelegate {
    
    // MARK: - EndLocationTableViewCell
    
    func didDeleteButtonClicked(_ cell: EndLocationTableViewCell) {
        guard let annotation = cell.annotation else {
            return
        }
        
        mapViewEnd.removeAnnotation(annotation)
        tableView.reloadData()
    }
}
