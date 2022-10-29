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
    
    @IBOutlet weak var txfTitle: UITextField!
    @IBOutlet weak var txvContent: UITextView!
    @IBOutlet weak var mapViewStart: MKMapView!
    @IBOutlet weak var barBtnSubmit: UIBarButtonItem!
    
    
    
    // ====== View Model ========= //
    var todoTitle = BehaviorRelay<String>(value: "")
    var content = BehaviorRelay<String>(value: "")
    var startCoord = BehaviorRelay<CLLocationCoordinate2D>(value: CLLocationCoordinate2D())
    
    var isValid: Observable<Bool> {
        return Observable.combineLatest(todoTitle.asObservable(),
                                        content.asObservable(),
                                        startCoord.asObservable()) { title, content, startCoord in
            
            return title.count >= 1 && content.count >= 1
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapViewStart.delegate = self
        
        _ = txfTitle.rx.text.map({ $0 ?? ""}).bind(to: todoTitle)
        _ = txvContent.rx.text.map({ $0 ?? ""}).bind(to: content)
        
        _ = isValid.subscribe(onNext: { [unowned self] isValid in
            barBtnSubmit.isEnabled = isValid
        })
        
        // barBtn Clicked
        _ = barBtnSubmit.rx.tap.subscribe(onNext: { [unowned self] in
            print(todoTitle.value, content.value, startCoord.value)
            
            let todo = Todo(title: todoTitle.value,
                            content: content.value,
                            startCoord: "\(startCoord.value)",
                            endCoords: ["1", "2", "3"])
            
            FirestoreTodo.shared.addPost(todoRequest: todo) { documenID in
                SimpleAlert.present(message: "Success", title: "Add Todo") { _ in
                    self.navigationController?.popViewController(animated: true)
                }
                
            }
        })
    }

    // MARK: - Table view data source

}

extension TodoUpdateTableViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        print(#function)
    }
    
    func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
        print(#function)
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        print(#function)
        startCoord.accept(mapView.centerCoordinate)
    }
}
