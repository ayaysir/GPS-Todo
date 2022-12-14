//
//  TodoUpdateViewModel.swift
//  GPS-Todo
//
//  Created by yoonbumtae on 2022/11/03.
//

import CoreLocation
import RxSwift
import RxRelay

class TodoUpdateViewModel {
    
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
    
    var scheduleType = BehaviorRelay<TodoScheduleType>(value: .once)
    var schedulePerDay = BehaviorRelay<Int>(value: 1)
    
    var scheduleChanged: Observable<Bool> {
        return Observable.combineLatest(scheduleType.asObservable(),
                                        schedulePerDay.asObservable()) { type, perDay in
            return true
        }
    }
}
