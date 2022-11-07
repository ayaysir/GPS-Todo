//
//  TodoScheduleType.swift
//  GPS-Todo
//
//  Created by yoonbumtae on 2022/11/08.
//

import Foundation

/// - once: 한 번 체크하면 완전 종료
/// - multiple: 여러 번 체크 가능하게
enum TodoScheduleType: Codable, CaseIterable {
    case once, multiple
    
    func textValue(_ perDay: Int = 0) -> String {
        switch self {
        case .once:
            return "Once Only"
        case .multiple:
            return "Per \(perDay) days"
        }
    }
}
