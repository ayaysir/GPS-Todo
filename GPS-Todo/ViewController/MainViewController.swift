//
//  MainViewController.swift
//  GPS-Todo
//
//  Created by yoonbumtae on 2022/10/11.
//

import UIKit
import FirebaseEmailAuthUI
import FirebaseGoogleAuthUI
import FirebaseOAuthUI
import CoreLocation

class MainViewController: UIViewController {
    
    @IBOutlet weak var btnLogInOut: UIButton!
    @IBOutlet weak var lblUserStatus: UILabel!
    
    // Instance Variables
    var handle: AuthStateDidChangeListenerHandle!
    private let locationManager = GPSLocationManager()
    
    // Unhashed nonce (Apple Login).
    fileprivate var currentNonce: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        switch locationManager.authStatus {
        case .notDetermined, .authorizedAlways, .authorizedWhenInUse:
            print("Allowed")
        case .restricted:
            break
        case .denied:
            break
        @unknown default:
            break
        }
        
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
            FUIOAuth.appleAuthProvider(withAuthUI: authUI),
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
    
    @IBAction func stepperActCount(_ sender: UIStepper) {
        // lblCount.text = "\(sender.value)"
    }
    
}

extension MainViewController: FUIAuthDelegate {
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        if let error = error {
            print(error)
            return
        }
        
        guard let authDataResult = authDataResult else {
            return
        }

        print(authDataResult.credential?.provider)
    }
    
    func emailEntryViewController(forAuthUI authUI: FUIAuth) -> FUIEmailEntryViewController {
        return EmailEntryViewController(nibName: "EmailEntryViewController", bundle: Bundle.main, authUI: authUI)
    }
    
    func passwordSignUpViewController(forAuthUI authUI: FUIAuth, email: String?, requireDisplayName: Bool) -> FUIPasswordSignUpViewController {
        return PasswordSignUpViewController(nibName: "PasswordSignUpViewController", bundle: Bundle.main, authUI: authUI, email: email, requireDisplayName: requireDisplayName)
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

extension MainViewController: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        false
    }
}

// import CryptoKit
// import AuthenticationServices
//
// extension ViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
//
//     // MARK: - ASAuthorizationControllerDelegate Methods
//
//     func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
//         return ASPresentationAnchor()
//     }
//
//     func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
//         if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
//             guard let nonce = currentNonce else {
//                 fatalError("Invalid state: A login callback was received, but no login request was sent.")
//             }
//             guard let appleIDToken = appleIDCredential.identityToken else {
//                 print("Unable to fetch identity token")
//                 return
//             }
//             guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
//                 print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
//                 return
//             }
//             // Initialize a Firebase credential.
//             let credential = OAuthProvider.credential(withProviderID: "apple.com",
//                                                       idToken: idTokenString,
//                                                       rawNonce: nonce)
//             // Sign in with Firebase.
//             Auth.auth().signIn(with: credential) { (authResult, error) in
//                 if let error = error {
//                     // Error. If error.code == .MissingOrInvalidNonce, make sure
//                     // you're sending the SHA256-hashed nonce as a hex string with
//                     // your request to Apple.
//                     print(error.localizedDescription)
//                     return
//                 }
//                 // User is signed in to Firebase with Apple.
//                 // ...
//             }
//         }
//     }
//
//     func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
//         // Handle error.
//         print("Sign in with Apple errored: \(error)")
//     }
//
//
//     // MARK: - Apple Login
//
//     @available(iOS 13, *)
//     func startSignInWithAppleFlow() {
//         let nonce = randomNonceString()
//         currentNonce = nonce
//         let appleIDProvider = ASAuthorizationAppleIDProvider()
//         let request = appleIDProvider.createRequest()
//         request.requestedScopes = [.fullName, .email]
//         request.nonce = sha256(nonce)
//
//         let authorizationController = ASAuthorizationController(authorizationRequests: [request])
//         authorizationController.delegate = self
//         authorizationController.presentationContextProvider = self
//         authorizationController.performRequests()
//     }
//
//     // Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
//     private func randomNonceString(length: Int = 32) -> String {
//         precondition(length > 0)
//         let charset: [Character] =
//         Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
//         var result = ""
//         var remainingLength = length
//
//         while remainingLength > 0 {
//             let randoms: [UInt8] = (0 ..< 16).map { _ in
//                 var random: UInt8 = 0
//                 let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
//                 if errorCode != errSecSuccess {
//                     fatalError(
//                         "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
//                     )
//                 }
//                 return random
//             }
//
//             randoms.forEach { random in
//                 if remainingLength == 0 {
//                     return
//                 }
//
//                 if random < charset.count {
//                     result.append(charset[Int(random)])
//                     remainingLength -= 1
//                 }
//             }
//         }
//
//         return result
//     }
//
//     @available(iOS 13, *)
//     private func sha256(_ input: String) -> String {
//         let inputData = Data(input.utf8)
//         let hashedData = SHA256.hash(data: inputData)
//         let hashString = hashedData.compactMap {
//             String(format: "%02x", $0)
//         }.joined()
//
//         return hashString
//     }
//
// }
