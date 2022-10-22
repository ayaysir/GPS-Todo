//
//  PasswordSignUpViewController.swift
//  GPS-Todo
//
//  Created by yoonbumtae on 2022/10/20.
//

import UIKit
import FirebaseAuth
import FirebaseAuthUI
import FirebaseEmailAuthUI
import RxSwift
import RxCocoa

/// @var kCellReuseIdentifier
/// The reuse identifier for table view cell.
private let kCellReuseIdentifier = "cellReuseIdentifier"

/// @var kEmailSignUpCellAccessibilityID
/// The Accessibility Identifier for the @c email cell.
private let kEmailSignUpCellAccessibilityID = "EmailSignUpCellAccessibilityID"

/// @var kPasswordSignUpCellAccessibilityID
/// The Accessibility Identifier for the @c password cell.
private let kPasswordSignUpCellAccessibilityID = "PasswordSignUpCellAccessibilityID"

/// @var kNameSignUpCellAccessibilityID
/// The Accessibility Identifier for the @c name cell.
private let kNameSignUpCellAccessibilityID = "NameSignUpCellAccessibilityID"

/// @var kSaveButtonAccessibilityID
/// The Accessibility Identifier for the @c next button.
private let kSaveButtonAccessibilityID = "SaveButtonAccessibilityID"

/// @var kTextFieldRightViewSize
/// The height and width of the @c rightView of the password text field.
private let kTextFieldRightViewSize: CGFloat = 36.0

class PasswordSignUpViewController: FUIPasswordSignUpViewController {
    
    /// @var _email
    /// The @c email address of the user from the previous screen.
    private var email: String?
    
    /// @var _emailField
    /// The @c UITextField that user enters email address into.
    private var emailField: UITextField?
    
    /// @var _nameField
    /// The @c UITextField that user enters name into.
    private var nameField: UITextField?
    
    /// @var requireDisplayName
    /// Indicate weather display name field is required.
    private var requireDisplayName = false
    
    /// @var _passwordField
    /// The @c UITextField that user enters password into.
    private var passwordField: UITextField?
    
    private let OVERLAY_TAG = 39194456
    private var progressView: UIProgressView?
    
    /// @var _tableView
    /// The @c UITableView used to store all UI elements.
    @IBOutlet weak var tableView: UITableView!
    
    // RxSwift (나중에 뷰모델로 옮김)
    var password = BehaviorRelay<String>(value: "")
    var isAvailablePassword: Bool = false
    var checkPwdStrength: Observable<Int> {
        let regexes = [
            "[a-z]+",
            "[A-Z]+",
            "[0-9]+",
            "[$@#&!]+",
        ]
        
        return password.asObservable()
            .map { password in
                var strength = 0
                
                regexes.forEach { regex in
                    if password.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil {
                        strength += 1
                    }
                }
                return strength
            }
    }
    
    convenience init(
        authUI: FUIAuth,
        email: String?,
        requireDisplayName: Bool
    ) {
        self.init(
            nibName: NSStringFromClass(type(of: self).self),
            bundle: FUIEmailAuth.bundle(),
            authUI: authUI,
            email: email,
            requireDisplayName: requireDisplayName)
    }

    override init(
        nibName nibNameOrNil: String?,
        bundle nibBundleOrNil: Bundle?,
        authUI: FUIAuth,
        email: String?,
        requireDisplayName: Bool
    ) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil, authUI: authUI, email: email, requireDisplayName: requireDisplayName)
        self.email = email
        self.requireDisplayName = requireDisplayName
        title = FUILocalizedString(kStr_SignUpTitle)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(#function, #file)
        let saveButtonItem = FUIAuthBaseViewController.barItem(withTitle: FUILocalizedString(kStr_Save), target: self, action: #selector(save))
        saveButtonItem.accessibilityIdentifier = kSaveButtonAccessibilityID
        self.navigationItem.rightBarButtonItem = saveButtonItem
        
        self.enableDynamicCellHeight(for: tableView)
        
        tableView.backgroundColor = UIColor.systemBackground
        
        // 패스워드 체크
        _ = checkPwdStrength.subscribe(onNext: { [unowned self] strength in
            var progressColor: UIColor = .red
            
            switch strength {
            case 2, 3:
                progressColor = .orange
            case 4:
                progressColor = .systemGreen
            default:
                progressColor = .red
                
            }
            
            let count = password.value.count
            let countCondition = count >= 6 && count <= 16
            
            // print("strength:", strength, password.value)
            // print("countCondition:", countCondition)
            
            if !countCondition {
                progressColor = .red
            }
            self.isAvailablePassword = strength >= 2 && countCondition
            saveButtonItem.isEnabled = self.isAvailablePassword
            
            self.progressView?.progressTintColor = progressColor
            self.progressView?.setProgress(Float(strength) / 4.0, animated: true)
            
        })
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.footerView.authUI = self.authUI
        self.footerView.useFooterMessage()
    }
    
    // MARK: - Actions
    
    @objc func save() {
        guard let emailFieldText = emailField?.text,
              let passwordFieldText = passwordField?.text,
              let nameFieldText = nameField?.text
        else {
            print(#line, "guard error")
            return
        }

        self.signUp(withEmail: emailFieldText, andPassword: passwordFieldText, andUsername: nameFieldText)
    }
    
    override func signUp(withEmail email: String, andPassword password: String, andUsername username: String) {
        if !PasswordSignUpViewController.isValidEmail(email) {
            showAlert(withMessage: FUILocalizedString(kStr_InvalidEmailError))
            return
        }
        
        if password.count <= 0 {
            showAlert(withMessage: FUILocalizedString(kStr_InvalidPasswordError))
            return
        }
        
        if !isAvailablePassword {
            showAlert(withMessage: "패스워드는 안전도 2 이상이어야 합니다.")
            return
        }

        incrementActivity()

        toggleOverlay(true)
        // Check for the presence of an anonymous user and whether automatic upgrade is enabled.
        if let user = auth.currentUser,
            user.isAnonymous && authUI.shouldAutoUpgradeAnonymousUsers {
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            user.link(with: credential) { [self] authResult, error in
                if let error = error {
                    decrementActivity()
                    self.finishSignUp(with: nil, error: error as? AuthErrorCode)
                    return
                }
                
                let request = authResult?.user.createProfileChangeRequest()
                request?.displayName = username
                request?.commitChanges() { [self] error in
                    decrementActivity()
                    if let error = error {
                        self.finishSignUp(with: nil, error: error as? AuthErrorCode)
                        return
                    }
                    
                    self.finishSignUp(with: authResult, error: nil)
                }
            }
        } else {
            auth.createUser(
                withEmail: email,
                password: password) { [self] authDataResult, error in
                    if let error = error {
                        decrementActivity()
                        
                        self.finishSignUp(with: nil, error: error as? AuthErrorCode)
                        return
                    }
                    
                    let request = authDataResult?.user.createProfileChangeRequest()
                    request?.displayName = username
                    request?.commitChanges() { [self] error in
                        self.decrementActivity()
                        
                        if let error = error {
                            self.finishSignUp(with: nil, error: error as? AuthErrorCode)
                            return
                        }
                        
                        self.finishSignUp(with: authDataResult, error: nil)
                    }
                }
            
        }
    }
    
    func finishSignUp(with authDataResult: AuthDataResult?, error: AuthErrorCode?) {
        if let error = error {
            toggleOverlay(false)
            switch error.code {
            case .emailAlreadyInUse:
                self.showAlert(withMessage: FUILocalizedString(kStr_EmailAlreadyInUseError))
                return
            case .invalidEmail:
                self.showAlert(withMessage: FUILocalizedString(kStr_InvalidEmailError))
                return
            case .weakPassword:
                self.showAlert(withMessage: FUILocalizedString(kStr_WeakPasswordError))
                return
            case .tooManyRequests:
                self.showAlert(withMessage: FUILocalizedString(kStr_SignUpTooManyTimesError))
                return
            default:
                return
            }
        }
        
        self.navigationController?.dismiss(animated: true) {
            self.authUI.invokeResultCallback(with: authDataResult, url: nil, error: error)
        }
    }
    
    @objc func textFieldDidChange() {
        guard let emailFieldText = emailField?.text,
              let pwdFieldText = passwordField?.text,
              let username = nameField?.text else {
            print(#line, "guard error")
            return
        }
        
        self.didChange(email: emailFieldText, password: pwdFieldText, userName: username)
    }
    
    @objc override func didChangeEmail(_ email: String, orPassword password: String, orUserName username: String) {
        var enableActionButton = email.count > 0 && password.count > 0
        if requireDisplayName {
            enableActionButton = enableActionButton && username.count > 0
        }
        navigationItem.rightBarButtonItem?.isEnabled = enableActionButton
    }
    
    func didChange(email: String, password: String, userName: String) {
        var enableActionButton = email.count > 0 && password.count > 0
        if requireDisplayName {
            enableActionButton = enableActionButton && userName.count > 0
        }
        self.navigationItem.rightBarButtonItem?.isEnabled = enableActionButton
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

extension PasswordSignUpViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            nameField?.becomeFirstResponder()
        } else if textField == nameField {
            passwordField?.becomeFirstResponder()
        } else if textField == passwordField {
            guard let emailFieldText = emailField?.text,
                  let pwdFieldText = passwordField?.text,
                  let username = nameField?.text else {
                print(#line, "guard error")
                return false
            }
            
            signUp(
                withEmail: emailFieldText,
                andPassword: pwdFieldText,
                andUsername: username)
        }
        return false
    }
}

extension PasswordSignUpViewController: UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Table View Delegate & DataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if requireDisplayName {
            return 4
        } else {
            return 3
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (requireDisplayName && indexPath.row == 3) || (!requireDisplayName && indexPath.row == 2) {
            return 10
        }
        
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: kCellReuseIdentifier) as? FUIAuthTableViewCell
        
        if cell == nil {
            let cellNib = UINib(
                nibName: NSStringFromClass(FUIAuthTableViewCell.self.self),
                bundle: FUIAuthUtils.authUIBundle())
            tableView.register(cellNib, forCellReuseIdentifier: kCellReuseIdentifier)
            cell = tableView.dequeueReusableCell(withIdentifier: kCellReuseIdentifier) as? FUIAuthTableViewCell
        }
        
        guard let cell = cell else {
            print(#line, "guard error")
            return UITableViewCell()
        }
        
        cell.textField.delegate = self
        
        if indexPath.row == 0 {
            setEmailField(cell: cell)
        }
        
        if requireDisplayName {
            switch indexPath.row {
            case 1:
                setNameField(cell: cell)
            case 2:
                setPasswordField(cell: cell)
            case 3:
                return pwdStrengthProgressBar()
            default:
                break
            }
        } else {
            switch indexPath.row {
            case 1:
                setPasswordField(cell: cell)
            case 2:
                break
            default:
                break
            }
        }
  
        cell.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        let emailFieldText = emailField?.text ?? ""
        let pwdFieldText = passwordField?.text ?? ""
        let username = nameField?.text ?? ""
        
        self.didChange(email: emailFieldText, password: pwdFieldText, userName: username)
        return cell
    }
    
    private func setEmailField(cell: FUIAuthTableViewCell) {
        cell.label.text = FUILocalizedString(kStr_Email)
        cell.accessibilityIdentifier = kEmailSignUpCellAccessibilityID
        cell.textField.isEnabled = false
        emailField = cell.textField
        emailField?.text = email
        emailField?.placeholder = FUILocalizedString(kStr_EnterYourEmail)
        emailField?.isSecureTextEntry = false
        emailField?.returnKeyType = .next
        emailField?.keyboardType = .emailAddress
        emailField?.autocorrectionType = .no
        emailField?.autocapitalizationType = .none
        emailField?.textContentType = .username
    }
    
    private func setNameField(cell: FUIAuthTableViewCell) {
        cell.label.text = FUILocalizedString(kStr_Name)
        cell.accessibilityIdentifier = kNameSignUpCellAccessibilityID
        nameField = cell.textField
        nameField?.placeholder = FUILocalizedString(kStr_FirstAndLastName)
        nameField?.isSecureTextEntry = false
        nameField?.returnKeyType = .next
        nameField?.keyboardType = .default
        nameField?.autocapitalizationType = .words
        nameField?.textContentType = .name
    }
    
    private func setPasswordField(cell: FUIAuthTableViewCell) {
        cell.label.text = FUILocalizedString(kStr_Password)
        cell.accessibilityIdentifier = kPasswordSignUpCellAccessibilityID
        passwordField = cell.textField
        passwordField?.placeholder = FUILocalizedString(kStr_ChoosePassword)
        passwordField?.isSecureTextEntry = true
        passwordField?.rightView = visibilityToggleButtonForPasswordField()
        passwordField?.rightViewMode = .always
        passwordField?.returnKeyType = .next
        passwordField?.keyboardType = .default
        passwordField?.textContentType = .password
        
        _ = passwordField?.rx.text.map({ $0 ?? "" }).bind(to: password)
        
    }
    
    private func pwdStrengthProgressBar() -> UITableViewCell {
        let frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 10)
        let cell = UITableViewCell()
        progressView = UIProgressView(frame: frame)
        progressView?.progressTintColor = .red
        progressView?.progress = 0.0
        cell.contentView.addSubview(progressView!)
        return cell
    }
}

extension PasswordSignUpViewController {
    
    func visibilityToggleButtonForPasswordField() -> UIButton? {
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 0, y: 0, width: kTextFieldRightViewSize, height: kTextFieldRightViewSize)
        button.tintColor = .lightGray
        updateIcon(forRightViewButton: button)
        button.addTarget(
            self,
            action: #selector(togglePasswordFieldVisibility(_:)),
            for: .touchUpInside)
        return button
    }
    
    func updateIcon(forRightViewButton button: UIButton?) {
        let imageName = passwordField!.isSecureTextEntry ? "ic_visibility" : "ic_visibility_off"
        let image = FUIAuthUtils.imageNamed(imageName, from: FUIAuthUtils.authUIBundle())
        button?.setImage(image, for: .normal)
    }
    
    @objc func togglePasswordFieldVisibility(_ button: UIButton?) {
        // Make sure cursor is placed correctly by disabling and enabling the text field.
        guard let passwordField = passwordField else {
            print(#line, "guard error")
            return
        }
        
        passwordField.isEnabled = false
        passwordField.isSecureTextEntry = !passwordField.isSecureTextEntry
        updateIcon(forRightViewButton: button)
        passwordField.isEnabled = true
        passwordField.becomeFirstResponder()
    }
}
