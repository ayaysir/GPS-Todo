//
//  ViewController.swift
//  GPS-Todo
//
//  Created by yoonbumtae on 2022/10/11.
//

import UIKit
import FirebaseEmailAuthUI
import FirebaseGoogleAuthUI

class ViewController: UIViewController {
    
    @IBOutlet weak var btnLogInOut: UIButton!
    @IBOutlet weak var lblUserStatus: UILabel!
    
    // Instance Variables
    var handle: AuthStateDidChangeListenerHandle!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        handle = Auth.auth().addStateDidChangeListener { auth, user in
            if let user = user, let email = user.email {
                self.lblUserStatus.text = "Logined: \(email)"
                self.btnLogInOut.setTitle("Log Out", for: .normal)
            } else {
                self.lblUserStatus.text = "Not Logined:"
                self.btnLogInOut.setTitle("Log In", for: .normal)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        guard Auth.auth().currentUser == nil else {
            return
        }
        
        guard let authUI = FUIAuth.defaultAuthUI() else {
            return
        }
        authUI.delegate = self
        
        let providers: [FUIAuthProvider] = [
            FUIEmailAuth(),
            FUIGoogleAuth(authUI: authUI),
        ]
        authUI.providers = providers
        
        // ⚠️: 이용약관과 개인정보보정책은 반드시 쌍으로 추가해야 함
        // 이용약관
        let kFirebaseTermsOfService = URL(string: "https://firebase.google.com/terms/")!
        authUI.tosurl = kFirebaseTermsOfService
        
        // 개인정보 보호정책
        let kFirebasePrivacyPolicy = URL(string: "https://policies.google.com/privacy")!
        authUI.privacyPolicyURL = kFirebasePrivacyPolicy
        
        // let authViewController = authUI?.authViewController() // 기본 제공 뷰 컨트롤러
        // self.present(authViewController!, animated: true)
        
        let customLoginVC = LoginCustomViewController(authUI: authUI)
        let naviVC = UINavigationController(rootViewController: customLoginVC)
        naviVC.presentationController?.delegate = self
        // naviVC.isNavigationBarHidden = true
        
        self.present(naviVC, animated: true)
    }

    @IBAction func btnActLogInout(_ sender: UIButton) {
        
        if Auth.auth().currentUser == nil {
            viewDidAppear(true)
            return
        }
        
        do {
            try Auth.auth().signOut()
        } catch {
            print(error.localizedDescription)
        }
    }
}

extension ViewController: FUIAuthDelegate {
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        if let error = error {
            print(error)
            return
        }
    }
    
    // func emailEntryViewController(forAuthUI authUI: FUIAuth) -> FUIEmailEntryViewController {
    //
    //   return CustomEmailViewController(nibName: nil, bundle: nil, authUI: authUI)
    // }
    
    // func authPickerViewController(forAuthUI authUI: FUIAuth) -> FUIAuthPickerViewController {
    //     let customVC = LoginCustomViewController(authUI: authUI)
    //     return customVC
    // }

}

extension ViewController: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        false
    }
}
