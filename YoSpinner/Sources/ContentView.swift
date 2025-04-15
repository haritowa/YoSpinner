import UIKit
import ObjectiveC

class ViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - Properties
    
    private let spinnerModel = SFSpinnerModel(
        numberOfSymbols: 4,
        symbolPool: [
            "microphone.circle.fill",
            "message.circle.fill",
            "phone.circle.fill",
            "video.circle.fill",
            "envelope.circle.fill",
            "recordingtape.circle.fill",
            "personalhotspot.circle.fill",
            "icloud.circle.fill",
            "wifi.circle.fill",
            "antenna.radiowaves.left.and.right.circle.fill",
            "play.circle.fill",
            "pause.circle.fill",
            "stop.circle.fill",
            "record.circle.fill",
            "shuffle.circle.fill",
            "repeat.circle.fill",
            "infinity.circle.fill",
            "popcorn.circle.fill",
            "house.circle.fill",
            "restart.circle.fill",
            "power.circle.fill",
            "speaker.wave.2.circle.fill",
            "iphone.circle.fill"
        ]
    )

    private let textFieldSpinnerModel = SFSpinnerModel(
        numberOfSymbols: 6,
        symbolPool: [
            "microphone.circle.fill",
            "message.circle.fill",
            "phone.circle.fill",
            "video.circle.fill",
            "envelope.circle.fill",
            "recordingtape.circle.fill",
            "personalhotspot.circle.fill",
            "icloud.circle.fill",
            "wifi.circle.fill",
            "antenna.radiowaves.left.and.right.circle.fill",
            "play.circle.fill",
            "pause.circle.fill",
            "stop.circle.fill",
            "record.circle.fill",
            "shuffle.circle.fill",
            "repeat.circle.fill",
            "infinity.circle.fill",
            "popcorn.circle.fill",
            "house.circle.fill",
            "restart.circle.fill",
            "power.circle.fill",
            "speaker.wave.2.circle.fill",
            "iphone.circle.fill"
        ]
    )
    
    // Track spinner states
    private var isButtonSpinnerActive = false
    private var isTextFieldSpinnerActive = false
    
    // Only need end button now
    private lazy var endButton: UIButton = createButton(title: "End Spinners", action: #selector(didTapEnd))
    
    // Add a container for the text field
    private lazy var textFieldContainer: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .systemGray6
        container.layer.cornerRadius = 12
        container.layer.masksToBounds = true
        return container
    }()
    
    // Add a text field above the button
    private lazy var textField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.placeholder = "Type here and tap outside..."
        field.borderStyle = .none
        field.backgroundColor = .clear // Make background clear so container shows through
        field.textAlignment = .center
        field.delegate = self
        field.returnKeyType = .done
        // Add some padding to the text field
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: field.frame.height))
        field.leftView = paddingView
        field.leftViewMode = .always
        field.rightView = paddingView
        field.rightViewMode = .always
        return field
    }()
    
    // Add a large orange button as background content
    private lazy var contentButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Tap Me To Spin", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 24)
        button.backgroundColor = .systemOrange
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(didTapContentButton), for: .touchUpInside)
        return button
    }()
    
    // Custom colors for spinner tinting
    private let orangeTint = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0) // Brighter orange
    private let blueTint = UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0) // Brighter blue
    
    // Helper method to apply custom tint to spinner
    private func customizeSpinner(_ spinner: SFSpinnerBar, withTintColor tintColor: UIColor, borderColor: CGColor? = nil) {
        // Find the spinner view
        guard let spinnerView = spinner as? UIView else { return }
        
        // Look for the blur view in the first level of subviews
        guard let blurView = spinnerView.subviews.first(where: { $0 is UIVisualEffectView }) as? UIVisualEffectView else { return }
        
        // Look for the vibrancy view inside blur content view
        if let vibrancyView = blurView.contentView.subviews.first(where: { $0 is UIVisualEffectView }) as? UIVisualEffectView {
            // Apply tint to vibrancy content view for icons
            vibrancyView.contentView.tintColor = tintColor
        }
        
        // Update border color if provided
        if let borderColor = borderColor {
            blurView.layer.borderColor = borderColor
            blurView.layer.borderWidth = 0.5
        }
    }

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        print("ViewController viewDidLoad - UI Setup Complete")
        
        // Initially hide the end button
        endButton.isHidden = true
        
        // Dismiss keyboard when tapping outside
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Add text field container
        view.addSubview(textFieldContainer)
        
        // Add text field inside container
        textFieldContainer.addSubview(textField)
        
        // Add content button
        view.addSubview(contentButton)
        
        // Add end button at the bottom
        view.addSubview(endButton)
        
        // Layout
        NSLayoutConstraint.activate([
            // Text Field Container Constraints
            textFieldContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            textFieldContainer.bottomAnchor.constraint(equalTo: contentButton.topAnchor, constant: -20),
            textFieldContainer.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            textFieldContainer.heightAnchor.constraint(equalToConstant: 50),
            
            // Text Field Constraints (fill container)
            textField.topAnchor.constraint(equalTo: textFieldContainer.topAnchor),
            textField.bottomAnchor.constraint(equalTo: textFieldContainer.bottomAnchor),
            textField.leadingAnchor.constraint(equalTo: textFieldContainer.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: textFieldContainer.trailingAnchor),
            
            // Content Button Constraints (Centered, Large)
            contentButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            contentButton.heightAnchor.constraint(equalToConstant: 100),
            
            // End Button Constraints (Bottom)
            endButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            endButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            endButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5),
            endButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func createButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // Start spinner on the text field container when editing ends
        if !isTextFieldSpinnerActive {
            isTextFieldSpinnerActive = true
            
            // Apply spinner to the container rather than the text field
            // Use smaller icons and larger insets for the text field container
            let spinner = textFieldContainer.startSpinner(
                model: textFieldSpinnerModel,
                contentInsets: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10),
                adaptToContainer: true,
                iconSize: 28.0,
                cornerRadius: textFieldContainer.layer.cornerRadius
            ) {
                print("Text field spinner started")
                
                // Show end button if any spinner is active
                self.updateEndButtonVisibility()
            }
            
            // Apply custom blue tint
            customizeSpinner(
                spinner,
                withTintColor: blueTint,
                borderColor: blueTint.withAlphaComponent(0.3).cgColor
            )
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: - Actions
    
    @objc private func didTapContentButton() {
        print("Content button tapped")
        
        // Don't do anything if spinner is already active
        if isButtonSpinnerActive {
            return
        }
        
        // Start spinner on the orange button with proper corner radius
        isButtonSpinnerActive = true
        let spinner = contentButton.startSpinner(
            model: spinnerModel,
            contentInsets: UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15),
            adaptToContainer: true,
            iconSize: 36.0,
            cornerRadius: contentButton.layer.cornerRadius
        ) {
            print("Button spinner started")
            
            // Show end button if any spinner is active
            self.updateEndButtonVisibility()
        }
        
        // Apply custom orange tint
        customizeSpinner(
            spinner, 
            withTintColor: orangeTint,
            borderColor: orangeTint.withAlphaComponent(0.3).cgColor
        )
    }
    
    @objc private func didTapEnd() {
        print("End button tapped")
        
        // End spinner on the orange button if active
        if isButtonSpinnerActive {
            contentButton.endSpinner {
                print("Button spinner ended")
                self.isButtonSpinnerActive = false
                self.updateEndButtonVisibility()
            }
        }
        
        // End spinner on the text field container if active
        if isTextFieldSpinnerActive {
            textFieldContainer.endSpinner {
                print("Text field spinner ended")
                self.isTextFieldSpinnerActive = false
                self.updateEndButtonVisibility()
            }
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func updateEndButtonVisibility() {
        // Show end button only if any spinner is active
        endButton.isHidden = !isButtonSpinnerActive && !isTextFieldSpinnerActive
    }
}
