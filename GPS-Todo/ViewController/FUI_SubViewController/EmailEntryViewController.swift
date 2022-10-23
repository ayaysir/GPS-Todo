//
//  EmailFormViewController.swift
//  GPS-Todo
//
//  Created by yoonbumtae on 2022/10/24.
//

import UIKit
import FirebaseAuth
import FirebaseAuthUI
import FirebaseEmailAuthUI

/*
 static NSString *const kCellReuseIdentifier = @"cellReuseIdentifier";
 -> private let kCellReuseIdentifier = "cellReuseIdentifier"
 */

/// The reuse identifier for table view cell.
private let kCellReuseIdentifier = "cellReuseIdentifier"

/// The key used to encode the app ID for NSCoding.
private let kAppIDCodingKey = "appID"

/// The key used to encode @c FUIAuth instance for NSCoding.
private let kAuthUICodingKey = "authUI"

/// The Accessibility Identifier for the @c email sign in cell.
private let kEmailCellAccessibilityID = "EmailCellAccessibilityID"

/// The Accessibility Identifier for the @c next button.
private let kNextButtonAccessibilityID = "NextButtonAccessibilityID"

class EmailEntryViewController: FUIEmailEntryViewController {
    
    /*
     UITextField *_emailField;
     var emailField: UITextField?
     */
    
    var emailField: UITextField?
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var termsOfServiceView: FUIPrivacyAndTermsOfServiceView!
    
    private let OVERLAY_TAG = 4995813
    
    convenience init(authUI: FUIAuth) {
        /*
         NSStringFromClass([self class])
         =>
         NSStringFromClass(type(of: self).self)
         */
        self.init(nibName: NSStringFromClass(type(of: self).self), bundle: FUIEmailAuth.bundle(), authUI: authUI)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?, authUI: FUIAuth) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil, authUI: authUI)
        
        self.title = FUILocalizedString(kStr_EnterYourEmail);
        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("최재훈 비의 랩소디")
        let nextButtonItem = FUIAuthBaseViewController.barItem(withTitle: FUILocalizedString(kStr_Next), target: self, action: #selector(nextStep))
        nextButtonItem.accessibilityIdentifier = kNextButtonAccessibilityID
        self.navigationItem.rightBarButtonItem = nextButtonItem
        termsOfServiceView.authUI = self.authUI
        termsOfServiceView.useFullMessage()
    }
    
    /*
     UIBarButtonItem *cancelBarButton =
         [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                       target:self
                                                       action:@selector(cancelAuthorization)];
     =>
     let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelAuthorization))
     */
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.navigationController?.viewControllers.first == self {
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelAuthorization))
            self.navigationItem.leftBarButtonItem = cancelBarButton
        }
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: FUILocalizedString(kStr_Back), style: .plain, target: nil, action: nil)
        
        if !self.authUI.isInteractiveDismissEnabled {
            self.isModalInPresentation = true
        }
    }
    
    // MARK: - Actions
    
    @objc func nextStep() {
        guard let email = emailField?.text else {
            return
        }

        self.onNext(email)
    }
    
    override func onNext(_ emailText: String) {

        guard let emailAuth = self.authUI.provider(withID: EmailAuthProviderID) as? FUIEmailAuth else {
            print(#line, "guard error")
            return
        }
        // id<FUIAuthDelegate> delegate = self.authUI.delegate;
        guard let delegate = authUI.delegate else {
            print(#line, "guard error")
            return
        }
        
        if !EmailEntryViewController.isValidEmail(emailText) {
            showAlert(withMessage: FUILocalizedString(kStr_InvalidEmailError))
            return
        }
        
        self.incrementActivity()
        toggleOverlay(true)
        
        self.auth.fetchSignInMethods(forEmail: emailText) { providers, error in
            self.decrementActivity()
            self.toggleOverlay(false)
            
            if let error = error as? AuthErrorCode {
                if error.code == .invalidEmail {
                    self.showAlert(withMessage: FUILocalizedString(kStr_InvalidEmailError))
                } else {
                    self.dismissNavigationController(animated: true) { [self] in
                        authUI.invokeResultCallback(with: nil, url: nil, error: error)
                    }
                }
                return
            }
            
            // provider.providerID != FIREmailAuthProviderID
            if let provider = self.bestProvider(fromProviderIDs: providers), provider.providerID != EmailAuthProviderID {
                let email = emailText
                EmailEntryViewController.showSignInAlert(
                    withEmail: email,
                    provider: provider,
                    presenting: self,
                    signinHandler: { [self] in
                        signInWithProvider(provider: provider, email: email)
                    },
                    cancelHandler: { [self] in
                        try? authUI.signOut()
                    })
                
            } else if let providers = providers, providers.contains(EmailAuthProviderID) {
                var controller: UIViewController? = nil
                if delegate.responds(to: #selector(FUIAuthDelegate.passwordSignInViewController(forAuthUI:email:))) {
                    controller = delegate.passwordSignInViewController!(
                        forAuthUI: self.authUI,
                        email: emailText)
                } else {
                    controller = FUIPasswordSignInViewController(
                        authUI: self.authUI,
                        email: emailText)
                }
                self.push(controller!)
            } else if emailAuth.signInMethod == EmailLinkAuthSignInMethod {
                // emailAuth.signInMethod == FIREmailLinkAuthSignInMethod
                self.sendSignInLink(toEmail: emailText)
            } else {
                if let providers = providers, providers.count > 0 {
                    // There's some unsupported providers, surface the error to the user.
                    self.showAlert(withMessage: FUILocalizedString(kStr_CannotAuthenticateError))
                } else {
                    // New user.
                    var controller: UIViewController? = nil
                    
                    if emailAuth.allowNewEmailAccounts {
                        if delegate.responds(to: #selector(FUIAuthDelegate.passwordSignUpViewController(forAuthUI:email:requireDisplayName:))) {
                            controller = delegate.passwordSignUpViewController!(
                                forAuthUI: self.authUI,
                                email: emailText,
                                requireDisplayName: emailAuth.requireDisplayName)
                        } else {
                            controller = FUIPasswordSignUpViewController(
                                authUI: self.authUI,
                                email: emailText,
                                requireDisplayName: emailAuth.requireDisplayName)
                        }
                    } else {
                        self.showAlert(withMessage: FUILocalizedString(kStr_UserNotFoundError))
                    }
                    
                    if let controller = controller {
                        self.push(controller)
                    }
                }
            }
        }
    }
    
    func sendSignInLink(toEmail: String) {
        
    }
    
    @objc func textFieldDidChange() {
        guard let email = emailField?.text else {
            return
        }
        didChangeEmail(email)
    }
    
    override func didChangeEmail(_ emailText: String) {
        enableNextButton(emailText.count > 0)
    }
    
    func bestProvider(fromProviderIDs providerIDs: [String]?) -> FUIAuthProvider? {
        let providers = authUI.providers
        for providerID in providerIDs ?? [] {
            for provider in providers {
                if providerID == provider.providerID {
                    return provider
                }
            }
        }
        return nil
    }
    
    func enableNextButton(_ isOn: Bool) {
        self.navigationItem.rightBarButtonItem?.isEnabled = isOn
    }
    
    func toggleOverlay(_ isOverlay: Bool) {
        let overlay = UIView(frame: CGRect(x: 0, y: 0, width: 1000, height: 1000))
        overlay.backgroundColor = .black
        overlay.alpha = 0.05
        overlay.tag = OVERLAY_TAG
        self.navigationItem.rightBarButtonItem?.isEnabled = !isOverlay
        self.navigationItem.hidesBackButton = isOverlay
        
        if isOverlay {
            self.view.addSubview(overlay)
        } else {
            self.view.subviews.forEach { subview in
                if subview.tag == OVERLAY_TAG {
                    subview.removeFromSuperview()
                }
            }
        }
    }
}

extension EmailEntryViewController: UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 1 {
            return 100
        }
        return UITableView.automaticDimension
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 1 {
            let cell = UITableViewCell()
            cell.selectionStyle = .none
            let label = UILabel(frame: CGRect(x: 10, y: 0, width: view.frame.width - 10, height: 100))
            label.text = "회원가입이 되어있지 않은 경우 새로운 이메일을 입력하면 회원가입 화면으로 이동합니다. 이미 가입한 경우 이메일을 입력하면 비밀번호 입력 화면으로 이동합니다."
            label.numberOfLines = 0
            cell.contentView.addSubview(label)
            return cell
        }
        
        var cell = tableView.dequeueReusableCell(withIdentifier: kCellReuseIdentifier) as? FUIAuthTableViewCell
        
        if cell == nil {
            let cellNib = UINib(nibName: NSStringFromClass(FUIAuthTableViewCell.self), bundle: FUIAuthUtils.authUIBundle())
            tableView.register(cellNib, forCellReuseIdentifier: kCellReuseIdentifier)
            cell = tableView.dequeueReusableCell(withIdentifier: kCellReuseIdentifier) as? FUIAuthTableViewCell
        }
        
        guard let cell = cell else {
            return UITableViewCell()
        }
        
        cell.label.text = FUILocalizedString(kStr_Email)
        cell.textField.placeholder = FUILocalizedString(kStr_EnterYourEmail)
        cell.textField.delegate = self
        cell.accessibilityIdentifier = kEmailCellAccessibilityID
        emailField = cell.textField;
        cell.textField.isSecureTextEntry = false
        cell.textField.autocorrectionType = .no
        cell.textField.autocapitalizationType = .none
        cell.textField.returnKeyType = .next
        cell.textField.keyboardType = .emailAddress
        cell.textField.textContentType = .username
        cell.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        if let email = emailField?.text {
            didChangeEmail(email)
        }
        return cell
        
    }
}

extension EmailEntryViewController: UITextFieldDelegate {
    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let emailField = emailField,
           let email = emailField.text,
            textField == emailField {
            self.onNext(email)
        }
        
        return false
    }
    
}

extension EmailEntryViewController {
    /** @fn signInWithProvider:email:
        @brief Actually kicks off sign in with the provider.
        @param provider The identity provider to sign in with.
        @param email The email address of the user.
     */
    func signInWithProvider(provider: FUIAuthProvider, email: String) {
        // Sign out first to make sure sign in starts with a clean state.
        provider.signOut()
        provider.signIn(withDefaultValue: email, presenting: self) { credential, error, result, userInfo in
            if let error = error {
                self.decrementActivity()
                if let result = result {
                    result(nil, error)
                }
                
                self.dismissNavigationController(animated: true) {
                    self.authUI.invokeResultCallback(with: nil, url: nil, error: error)
                }
                return
            }
            
            guard let credential = credential else {
                return
            }
            
            self.auth.signIn(with: credential) { authResult, error in
                self.decrementActivity()
                if let result = result,
                    let authResult = authResult {
                    result(authResult.user, error)
                }
                
                if let error = error {
                    self.authUI.invokeResultCallback(with: nil, url: nil, error: error)
                } else {
                    self.dismissNavigationController(animated: true) {
                        self.authUI.invokeResultCallback(with: authResult, url: nil, error: error)
                    }
                }
            }
            
        }
    }
}
