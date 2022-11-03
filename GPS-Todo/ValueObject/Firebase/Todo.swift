//
//  Todo.swift
//  GPS-Todo
//
//  Created by yoonbumtae on 2022/10/29.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Todo: Codable {
    
    // @DocumentID가 붙은 경우 Read시 해당 문서의 ID를 자동으로 할당
    @DocumentID var documentID: String?
    
    // @ServerTimestamp가 붙은 경우 Create, Update시 서버 시간을 자동으로 입력함 (FirebaseFirestoreSwift 디펜던시 필요)
    @ServerTimestamp var createdTimestamp: Timestamp?
    @ServerTimestamp var modifiedTimestamp: Timestamp?
    
    var title: String
    var content: String
    
    // time
    // ...
    
    var authorUID: String = ""
    
    // 좌표
    var startCoord: CoordInfo
    var endCoords: [CoordInfo]
    
    enum CodingKeys: String, CodingKey {
        case documentID = "document_id"
        case createdTimestamp = "created_timestamp"
        case modifiedTimestamp = "modified_timestamp"
        
        case authorUID = "author_uid"
        
        case startCoord = "start_coord"
        case endCoords = "end_coords"
        
        case title, content
    }
    
}
