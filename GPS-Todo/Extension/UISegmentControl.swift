//
//  UISegmentControl.swift
//  GPS-Todo
//
//  Created by yoonbumtae on 2022/11/04.
//

import UIKit

extension UISegmentedControl {
    func replaceSegments(segments: Array<String>) {
        self.removeAllSegments()
        for segment in segments {
            self.insertSegment(withTitle: segment, at: self.numberOfSegments, animated: false)
        }
    }
}
