//
//  CustomEmailViewController.swift
//  GPS-Todo
//
//  Created by yoonbumtae on 2022/10/18.
//

import Foundation
import FirebaseEmailAuthUI

class CustomEmailViewController: FUIEmailEntryViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("여기 뜨는거 맞아?")
        let width = UIScreen.main.bounds.size.width
        let height = UIScreen.main.bounds.size.height
        
        let label = UILabel(frame: CGRect(x: 100, y: 100, width: width - 20, height: 200))
        label.text = "가입을 하시려면 새로운 이메일을 입력하세요. 이미 가입이 되있다면 기존 이메일을 입력하세요."
        
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.numberOfLines = 0
        view.addSubview(label)
    }
    
    override func onNext(_ emailText: String) {
        print(emailText)
    }
}
