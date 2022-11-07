//
//  TodoCheck.swift
//  GPS-Todo
//
//  Created by yoonbumtae on 2022/11/08.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct TodoCheck: Codable {
    var userUID: String
    var todoDocumentID: String
    @ServerTimestamp var timestamp: Timestamp?
    
    enum CodingKeys: String, CodingKey {
        case userUID = "user_uid"
        case todoDocumentID = "todo_document_id"
        case timestamp
    }
}
