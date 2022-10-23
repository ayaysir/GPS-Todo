//
//  LoginCustomViewController.swift
//  GPS-Todo
//
//  Created by yoonbumtae on 2022/10/18.
//

import UIKit
import FirebaseAuthUI

class LoginCustomViewController: FUIAuthPickerViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let width = UIScreen.main.bounds.size.width
        // let height = UIScreen.main.bounds.size.height
        
        let imageView = UIImageView(image: UIImage(named: "StringQuartet"))
        view.addSubview(imageView)
        
        let label = UILabel(frame: CGRect(x: 10, y: 0, width: width - 20, height: 200))
        label.text = "이메일, 구글, 애플 로그인 중 하나를 선택해서 로그인하세요."
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.numberOfLines = 0
        view.addSubview(label)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}
