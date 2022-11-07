//
//  ScheduleSelectTableViewController.swift
//  GPS-Todo
//
//  Created by yoonbumtae on 2022/11/08.
//

import UIKit
import RxSwift

class ScheduleSelectTableViewController: UITableViewController {
    
    private let SECTION_SCHEDULE_TYPE = 0
    
    var viewModel: TodoUpdateViewModel!
    private let disposeBag = DisposeBag()
    
    @IBOutlet weak var stepperPerDay: UIStepper!
    @IBOutlet weak var lblPerDay: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        stepperPerDay.value = Double(viewModel.schedulePerDay.value)
        
        _ = stepperPerDay.rx.value
            .map(Int.init)
            .bind(to: viewModel.schedulePerDay)
            .disposed(by: disposeBag)
        
        _ = viewModel.schedulePerDay
            .map(String.init)
            .bind(to: lblPerDay.rx.text)
            .disposed(by: disposeBag)
        
        _ = viewModel.scheduleType
            .subscribe(onNext: { [unowned self] type in
                checkTypeCell(type)
            })
            .disposed(by: disposeBag)
    }
    
    private func checkTypeCell(_ type: TodoScheduleType) {
        TodoScheduleType.allCases.enumerated().forEach { (index, currType) in
            
            let cell = tableView.cellForRow(at: IndexPath(row: index, section: SECTION_SCHEDULE_TYPE))
            
            if currType == type {
                cell?.accessoryType = .checkmark
            } else {
                cell?.accessoryType = .none
            }
        }
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == SECTION_SCHEDULE_TYPE {
            switch indexPath.row {
            case 0:
                viewModel.scheduleType.accept(.once)
            case 1:
                viewModel.scheduleType.accept(.multiple)
            default:
                break
            }
        }
    }
}
