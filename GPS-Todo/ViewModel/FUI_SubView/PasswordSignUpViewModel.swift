//
//  PasswordSignUpViewModel.swift
//  GPS-Todo
//
//  Created by yoonbumtae on 2022/10/24.
//

import RxSwift
import RxRelay

struct PasswordSignUpViewModel {
    
    var name = BehaviorRelay<String>(value: "")
    var password = BehaviorRelay<String>(value: "")
    
    var isAvailablePassword: Bool {
        password.value.count > 0
    }
    var isAvailableUserName: Bool {
        name.value.count > 0
    }
    
    var checkPwdStrength: Observable<Int> {
        let regexes = [
            "[a-z]+",
            "[A-Z]+",
            "[0-9]+",
            "[$@#&!]+",
        ]
        
        return password.asObservable()
            .map { password in
                var strength = 0
                
                regexes.forEach { regex in
                    if password.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil {
                        strength += 1
                    }
                }
                return strength
            }
    }
    
    var isValid: Observable<Bool> {
        return Observable.combineLatest(name.asObservable(), password.asObservable(), checkPwdStrength) { name, password, strength in
            return isAvailablePassword && isAvailableUserName && (strength >= 2)
        }
    }
    
}
