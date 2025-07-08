//
//  DeviceLockViewController.swift
//  PerformanceTest
//
//  Created by Zheng, Haiqiang (Jason) on 2025/1/27.
//

import UIKit
import os.log
import LocalAuthentication

/// A view controller that monitors and displays device lock/unlock events
class DeviceLockViewController: UIViewController {
    
    // MARK: - Properties
    
    /// UI elements to display device lock status
    private let statusLabel = UILabel()
    private let lockTimeLabel = UILabel()
    private let unlockTimeLabel = UILabel()
    private let lockCountLabel = UILabel()
    private let unlockCountLabel = UILabel()
    private let authStatusLabel = UILabel()
    private let biometricTypeLabel = UILabel()
    private let eventHistoryTextView = UITextView()
    
    /// Screen state monitor for reusable lock/unlock detection
    private let screenStateMonitor = ScreenStateMonitor()
    
    /// Event history for UI display
    private var eventHistory: [String] = []
    
    /// Logger for tracking device lock events
    private let logger = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.performance.test", category: "DeviceLock")
    
    // MARK: - Constants
    
    private struct Constants {
        static let spacing: CGFloat = 20
        static let maxHistoryCount = 50
    }
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        os_log("DeviceLockViewController initialized", log: logger, type: .info)
        setupUI()
        setupScreenStateMonitor()
        updateInitialStatus()
    }
    
    deinit {
        os_log("DeviceLockViewController deinitialized", log: logger, type: .info)
    }
    
    // MARK: - Setup Methods
    
    /// Sets up the screen state monitor
    private func setupScreenStateMonitor() {
        screenStateMonitor.delegate = self
    }
    
    /// Updates the initial status from screen state monitor
    private func updateInitialStatus() {
        let state = screenStateMonitor.getCurrentState()
        let status = state.isLocked ? "Locked" : "Unlocked"
        statusLabel.text = "Device Status: \(status)"
        lockCountLabel.text = "Lock Count: \(state.lockCount)"
        unlockCountLabel.text = "Unlock Count: \(state.unlockCount)"
        
        addEventToHistory("Initial status: Device is \(status)")
        
        os_log("Initial device status: %{public}@", log: logger, type: .info, status)
    }
    
    /// Sets up the user interface elements
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Device Lock Test"
        
        // Create scroll view for content
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Title label
        let titleLabel = UILabel()
        titleLabel.text = "Device Lock/Unlock Monitor"
        titleLabel.textAlignment = .center
        titleLabel.font = .boldSystemFont(ofSize: 20)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Status label
        statusLabel.text = "Device Status: Unknown"
        statusLabel.textAlignment = .center
        statusLabel.font = .systemFont(ofSize: 16)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statusLabel)
        
        // Authentication status label
        authStatusLabel.text = "Auth Status: Checking..."
        authStatusLabel.textAlignment = .center
        authStatusLabel.font = .systemFont(ofSize: 14)
        authStatusLabel.textColor = .systemBlue
        authStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(authStatusLabel)
        
        // Biometric type label
        biometricTypeLabel.text = "Biometric Type: Unknown"
        biometricTypeLabel.textAlignment = .center
        biometricTypeLabel.font = .systemFont(ofSize: 14)
        biometricTypeLabel.textColor = .systemPurple
        biometricTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(biometricTypeLabel)
        
        // Lock time label
        lockTimeLabel.text = "Last Lock Time: -"
        lockTimeLabel.textAlignment = .center
        lockTimeLabel.font = .systemFont(ofSize: 14)
        lockTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(lockTimeLabel)
        
        // Unlock time label
        unlockTimeLabel.text = "Last Unlock Time: -"
        unlockTimeLabel.textAlignment = .center
        unlockTimeLabel.font = .systemFont(ofSize: 14)
        unlockTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(unlockTimeLabel)
        
        // Lock count label
        lockCountLabel.text = "Lock Count: 0"
        lockCountLabel.textAlignment = .center
        lockCountLabel.font = .systemFont(ofSize: 14)
        lockCountLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(lockCountLabel)
        
        // Unlock count label
        unlockCountLabel.text = "Unlock Count: 0"
        unlockCountLabel.textAlignment = .center
        unlockCountLabel.font = .systemFont(ofSize: 14)
        unlockCountLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(unlockCountLabel)
        
        // Event history label
        let historyLabel = UILabel()
        historyLabel.text = "Event History:"
        historyLabel.font = .boldSystemFont(ofSize: 16)
        historyLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(historyLabel)
        
        // Event history text view
        eventHistoryTextView.isEditable = false
        eventHistoryTextView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        eventHistoryTextView.backgroundColor = .systemGray6
        eventHistoryTextView.layer.cornerRadius = 8
        eventHistoryTextView.layer.borderWidth = 1
        eventHistoryTextView.layer.borderColor = UIColor.systemGray4.cgColor
        eventHistoryTextView.text = "Waiting for device lock/unlock events..."
        eventHistoryTextView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(eventHistoryTextView)
        
        // Refresh auth status button
        let refreshAuthButton = UIButton(type: .system)
        refreshAuthButton.setTitle("Refresh Auth Status", for: .normal)
        refreshAuthButton.backgroundColor = .systemGreen
        refreshAuthButton.setTitleColor(.white, for: .normal)
        refreshAuthButton.layer.cornerRadius = 8
        refreshAuthButton.addTarget(self, action: #selector(refreshAuthStatusTapped), for: .touchUpInside)
        refreshAuthButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(refreshAuthButton)
        
        // Clear history button
        let clearButton = UIButton(type: .system)
        clearButton.setTitle("Clear History", for: .normal)
        clearButton.backgroundColor = .systemBlue
        clearButton.setTitleColor(.white, for: .normal)
        clearButton.layer.cornerRadius = 8
        clearButton.addTarget(self, action: #selector(clearHistoryTapped), for: .touchUpInside)
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(clearButton)
        
        // Back button
        let backButton = UIButton(type: .system)
        backButton.setTitle("Back", for: .normal)
        backButton.backgroundColor = .systemGray
        backButton.setTitleColor(.white, for: .normal)
        backButton.layer.cornerRadius = 8
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(backButton)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Scroll view constraints
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view constraints
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Title label constraints
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Constants.spacing),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.spacing),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.spacing),
            
            // Status label constraints
            statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Constants.spacing),
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.spacing),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.spacing),
            
            // Auth status label constraints
            authStatusLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 10),
            authStatusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.spacing),
            authStatusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.spacing),
            
            // Biometric type label constraints
            biometricTypeLabel.topAnchor.constraint(equalTo: authStatusLabel.bottomAnchor, constant: 10),
            biometricTypeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.spacing),
            biometricTypeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.spacing),
            
            // Lock time label constraints
            lockTimeLabel.topAnchor.constraint(equalTo: biometricTypeLabel.bottomAnchor, constant: Constants.spacing),
            lockTimeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.spacing),
            lockTimeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.spacing),
            
            // Unlock time label constraints
            unlockTimeLabel.topAnchor.constraint(equalTo: lockTimeLabel.bottomAnchor, constant: 10),
            unlockTimeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.spacing),
            unlockTimeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.spacing),
            
            // Lock count label constraints
            lockCountLabel.topAnchor.constraint(equalTo: unlockTimeLabel.bottomAnchor, constant: Constants.spacing),
            lockCountLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.spacing),
            lockCountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.spacing),
            
            // Unlock count label constraints
            unlockCountLabel.topAnchor.constraint(equalTo: lockCountLabel.bottomAnchor, constant: 10),
            unlockCountLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.spacing),
            unlockCountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.spacing),
            
            // History label constraints
            historyLabel.topAnchor.constraint(equalTo: unlockCountLabel.bottomAnchor, constant: Constants.spacing),
            historyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.spacing),
            historyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.spacing),
            
            // Event history text view constraints
            eventHistoryTextView.topAnchor.constraint(equalTo: historyLabel.bottomAnchor, constant: 10),
            eventHistoryTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.spacing),
            eventHistoryTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.spacing),
            eventHistoryTextView.heightAnchor.constraint(equalToConstant: 200),
            
            // Refresh auth button constraints
            refreshAuthButton.topAnchor.constraint(equalTo: eventHistoryTextView.bottomAnchor, constant: Constants.spacing),
            refreshAuthButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.spacing),
            refreshAuthButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.spacing),
            refreshAuthButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Clear button constraints
            clearButton.topAnchor.constraint(equalTo: refreshAuthButton.bottomAnchor, constant: 10),
            clearButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.spacing),
            clearButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.spacing),
            clearButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Back button constraints
            backButton.topAnchor.constraint(equalTo: clearButton.bottomAnchor, constant: Constants.spacing),
            backButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.spacing),
            backButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.spacing),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            backButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Constants.spacing)
        ])
        
        os_log("UI setup completed", log: logger, type: .debug)
    }
    
    // MARK: - Action Methods
    
    @objc private func refreshAuthStatusTapped() {
        os_log("Refresh auth status button tapped", log: logger, type: .info)
        screenStateMonitor.refreshAuthenticationStatus()
    }
    
    @objc private func clearHistoryTapped() {
        eventHistory.removeAll()
        eventHistoryTextView.text = "Event history cleared."
        
        os_log("Event history cleared", log: logger, type: .info)
    }
    
    @objc private func backButtonTapped() {
        os_log("Back button tapped", log: logger, type: .info)
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Helper Methods
    
    private func formatCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
    
    private func addEventToHistory(_ event: String) {
        let timestamp = formatCurrentTime()
        let eventWithTimestamp = "[\(timestamp)] \(event)"
        
        eventHistory.append(eventWithTimestamp)
        
        // Limit history to prevent memory issues
        if eventHistory.count > Constants.maxHistoryCount {
            eventHistory.removeFirst()
        }
        
        // Update UI
        DispatchQueue.main.async { [weak self] in
            self?.eventHistoryTextView.text = self?.eventHistory.joined(separator: "\n")
            
            // Auto-scroll to bottom
            if let textView = self?.eventHistoryTextView {
                let bottom = NSMakeRange(textView.text.count - 1, 1)
                textView.scrollRangeToVisible(bottom)
            }
        }
    }
}

// MARK: - ScreenStateMonitorDelegate

extension DeviceLockViewController: ScreenStateMonitorDelegate {
    
    func screenStateMonitor(_ monitor: ScreenStateMonitor, didDetectLock lockTime: Date) {
        let currentTimeString = formatCurrentTime()
        let state = monitor.getCurrentState()
        
        lockTimeLabel.text = "Last Lock Time: \(currentTimeString)"
        lockCountLabel.text = "Lock Count: \(state.lockCount)"
        statusLabel.text = "Device Status: Locked"
        
        addEventToHistory("🔒 Device locked at \(currentTimeString)")
    }
    
    func screenStateMonitor(_ monitor: ScreenStateMonitor, didDetectUnlock unlockTime: Date) {
        let currentTimeString = formatCurrentTime()
        let state = monitor.getCurrentState()
        
        unlockTimeLabel.text = "Last Unlock Time: \(currentTimeString)"
        unlockCountLabel.text = "Unlock Count: \(state.unlockCount)"
        statusLabel.text = "Device Status: Unlocked"
        
        addEventToHistory("🔓 Device unlocked at \(currentTimeString)")
    }
    
    func screenStateMonitor(_ monitor: ScreenStateMonitor, didUpdateAuthStatus isPasscodeSet: Bool, biometricType: LABiometryType, error: Error?) {
        // Update auth status label
        if isPasscodeSet {
            authStatusLabel.text = "Auth Status: ✅ Passcode/Biometric Set"
            authStatusLabel.textColor = .systemGreen
        } else {
            authStatusLabel.text = "Auth Status: ❌ No Passcode Set"
            authStatusLabel.textColor = .systemRed
        }
        
        // Update biometric type label
        var biometricTypeText = "Biometric Type: "
        
        switch biometricType {
        case .none:
            biometricTypeText += "None Available"
            biometricTypeLabel.textColor = .systemGray
        case .touchID:
            biometricTypeText += "👆 Touch ID"
            biometricTypeLabel.textColor = .systemBlue
        case .faceID:
            biometricTypeText += "👤 Face ID"
            biometricTypeLabel.textColor = .systemPurple
        case .opticID:
            biometricTypeText += "👁️ Optic ID"
            biometricTypeLabel.textColor = .systemIndigo
        @unknown default:
            biometricTypeText += "Unknown Biometric"
            biometricTypeLabel.textColor = .systemOrange
        }
        
        if let error = error {
            biometricTypeText += " (\(error.localizedDescription))"
            biometricTypeLabel.textColor = .systemRed
        }
        
        biometricTypeLabel.text = biometricTypeText
        
        // Add to event history
        let authStatus = isPasscodeSet ? "Passcode/Biometric Set" : "No Passcode Set"
        addEventToHistory("🔐 Auth Check: \(authStatus)")
        
        if let error = error {
            addEventToHistory("⚠️ Auth Error: \(error.localizedDescription)")
        }
    }
    
    func screenStateMonitor(_ monitor: ScreenStateMonitor, didChangeBrightness brightness: CGFloat) {
        let brightnessPercentage = Int(brightness * 100)
        addEventToHistory("💡 Brightness: \(brightnessPercentage)%")
        
        if brightness == 0.0 {
            addEventToHistory("⚫ Brightness dropped to 0% - may indicate lock")
        }
    }
} 
