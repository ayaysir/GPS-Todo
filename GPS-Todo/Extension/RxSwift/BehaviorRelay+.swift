//
//  BehaviorRelay+.swift
//  GPS-Todo
//
//  Created by yoonbumtae on 2022/11/03.
//

import RxRelay

extension BehaviorRelay {
    
    /**
     array 타입의 BehaviorRelay에서 새로운 원소를 추가한다.
     */
    func acceptAndAppend(element: Any) {
        if self.value is Array<Any> {
            let array = self.value as! Array<Any>
            let newArray = array + [element]
            self.accept(newArray as! Element)
        } else {
            self.accept(element as! Element)
        }
    }
}
