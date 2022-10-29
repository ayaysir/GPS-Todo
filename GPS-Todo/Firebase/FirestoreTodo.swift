//
//  FirestoreTodo.swift
//  GPS-Todo
//
//  Created by yoonbumtae on 2022/10/29.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

class FirestoreTodo {
    
    static let shared = FirestoreTodo()
    
    typealias ErrorHandler = (_ err: Error) -> ()
    typealias ReadAllCompletionHandler = (_ todos: [Todo]) -> ()
    typealias QuerySnapshotListener = (QuerySnapshot?, Error?) -> ()
    
    var db: Firestore!
    var todoRef: CollectionReference!
    
    var currentUser: User? {
        return Auth.auth().currentUser
    }
    
    init() {
        // [START setup]
        let settings = FirestoreSettings()
        
        Firestore.firestore().settings = settings
        
        // [END setup]
        db = Firestore.firestore()
        
        todoRef = db.collection("todos")
    }
    
    func addPost(todoRequest request: Todo) {
        addPost(todoRequest: request) { documentID in
            print("Firestore>> Document added with ID: \(documentID)")
        }
    }
    
    func addPost(todoRequest request: Todo, completion: @escaping (_ documentID: String) -> ()) {
        var ref: DocumentReference? = nil
        
        do {
            ref = todoRef.document()
            
            guard let ref = ref else {
                print("Reference is not exist.")
                return
            }
            
            guard let currentUser = currentUser else {
                print("User not exist")
                return
            }
            
            var request = request
            request.authorUID = currentUser.uid
            
            try ref.setData(from: request) { err in
                if let err = err {
                    print("Firestore>> Error adding document: \(err)")
                    return
                }
                
                completion(ref.documentID)
            }
        } catch {
            print("Firestore>> Error from addPost-setData: ", error)
        }
    }
    
    private func querySnapshotListener(completionHandler: @escaping ReadAllCompletionHandler, errorHandler: ErrorHandler?) -> QuerySnapshotListener {
        
        return { snapshot, error in
            if let error = error {
                print("Firestore>> read failed", error)
                return
            }
            
            guard let snapshot = snapshot else {
                print("Firestore>> QuerySnapshot is nil")
                return
            }
            
            let todos = snapshot.documents.compactMap { documentSnapshot in
                try? documentSnapshot.data(as: Todo.self)
            }
            
            completionHandler(todos)
        }
    }

    
    func readAll(completionHandler: @escaping ([Todo]) -> ()) {
        // 서버 업로드 시간 기준으로 내림차순
        let query: Query = todoRef.order(by: Todo.CodingKeys.createdTimestamp.rawValue, descending: true)
        query.getDocuments { snapshot, error in
            if let error = error {
                print("Firestore>> read failed", error)
                return
            }
            
            guard let snapshot = snapshot else {
                print("Firestore>> QuerySnapshot is nil")
                return
            }
            
            let todos = snapshot.documents.compactMap { documentSnapshot in
                try? documentSnapshot.data(as: Todo.self)
            }
            
            completionHandler(todos)
        }
    }
    
    func listenAll(completionHandler: @escaping ([Todo]) -> ()) {
        let query: Query = todoRef.order(by: Todo.CodingKeys.createdTimestamp.rawValue, descending: true)
        query.addSnapshotListener(querySnapshotListener(completionHandler: completionHandler, errorHandler: nil))
        
    }
    
    func deletePost(documentID: String) {
        todoRef.document(documentID).delete() { err in
            if let err = err {
                print("Firestore>> Error deleting document: \(err)")
                return
            }
            
            print("Firestore>> Document deleted with ID: \(documentID)")
        }
    }

}
