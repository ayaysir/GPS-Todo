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
    
    func updateTodo(documentID: String, originalTodoRequest request: Todo, onCompletion: @escaping (_ documentId: String) -> ()) {
        
        do {
            // serverTS에는 값이 들어있으므로 업데이트시 시간이 바뀌지 않는다.
            // serverTS를 nil로 하면 새로운 시간이 부여된다.
            var request = request
            request.modifiedTimestamp = nil
            
            try todoRef.document(documentID).setData(from: request) { err in
                if let err = err {
                    print("Firestore>> Error updating document: \(err)")
                    return
                }
                
                print("Firestore>> Document updating with ID: \(documentID)")
                onCompletion(documentID)
            }
        } catch {
            print("Firestore>> Error from updatePost-setData: ", error)
        }
    }

}
