//
//  Double+.swift
//  GPS-Todo
//
//  Created by yoonbumtae on 2022/11/03.
//

import Foundation

extension Double {
    
    /// Rounds the double to decimal places value
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
