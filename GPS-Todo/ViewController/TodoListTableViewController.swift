//
//  TodoListTableViewController.swift
//  GPS-Todo
//
//  Created by yoonbumtae on 2022/10/29.
//

import UIKit
import BGSMM_DevKit

class TodoListTableViewController: UITableViewController {
    
    var list: [Todo] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        let todo = Todo(title: "Title \(Int.random(in: 111...999))",
                        content: "content",
                        startCoord: "",
                        endCoords: ["1", "2", "3"])
        
        FirestoreTodo.shared.addPost(todoRequest: todo)
        
        FirestoreTodo.shared.readAll { todos in
            self.list = todos
            self.tableView.reloadData()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return list.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TodoCell", for: indexPath) as? TodoCell else {
            return UITableViewCell()
        }

        // Configure the cell...
        cell.configure(todo: list[indexPath.row])

        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            SimpleAlert.yesAndNo(message: "Hontoni Delete?", title: "Delete", btnYesStyle: .destructive) { _ in
                
                // Delete the row from the data source
                let todo = self.list[indexPath.row]
                FirestoreTodo.shared.deletePost(documentID: todo.documentID!)
                self.list.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

class TodoCell: UITableViewCell {
    
    @IBOutlet weak var lblTitle: UILabel!
    
    func configure(todo: Todo) {
        lblTitle.text = "\(todo.title) \(todo.createdTimestamp?.seconds)"
    }
}
