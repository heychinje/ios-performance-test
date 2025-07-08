//
//  DeviceLockViewController.swift
//  PerformanceTest
//
//  Created by Zheng, Haiqiang (Jason) on 2025/1/27.
//

import UIKit
import os.log

/// A view controller that monitors and displays device lock/unlock events
class DeviceLockViewController: UIViewController {
    
    // MARK: - Properties
    
    /// UI elements to display device lock status
    private let statusLabel = UILabel()
    private let lockTimeLabel = UILabel()
    private let unlockTimeLabel = UILabel()
    private let lockCountLabel = UILabel()
    private let unlockCountLabel = UILabel()
    private let eventHistoryTextView = UITextView()
    
    /// Device lock tracking properties
    private var isDeviceLocked = false
    private var lockCount = 0
    private var unlockCount = 0
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
        setupNotifications()
        updateInitialStatus()
    }
    
    deinit {
        os_log("DeviceLockViewController deinitialized", log: logger, type: .info)
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup Methods
    
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
            
            // Lock time label constraints
            lockTimeLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: Constants.spacing),
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
            
            // Clear button constraints
            clearButton.topAnchor.constraint(equalTo: eventHistoryTextView.bottomAnchor, constant: Constants.spacing),
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
    
    /// Sets up notification observers for device lock/unlock events
    private func setupNotifications() {
        let notificationCenter = NotificationCenter.default
        
        // Listen for device lock notification
        notificationCenter.addObserver(
            self,
            selector: #selector(deviceDidLock),
            name: UIApplication.protectedDataWillBecomeUnavailableNotification,
            object: nil
        )
        
        // Listen for device unlock notification
        notificationCenter.addObserver(
            self,
            selector: #selector(deviceDidUnlock),
            name: UIApplication.protectedDataDidBecomeAvailableNotification,
            object: nil
        )
        
        // Listen for app entering background (may indicate lock)
        notificationCenter.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // Listen for app entering foreground (may indicate unlock)
        notificationCenter.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        os_log("Notification observers set up", log: logger, type: .debug)
    }
    
    /// Updates the initial status based on current device state
    private func updateInitialStatus() {
        let isProtectedDataAvailable = UIApplication.shared.isProtectedDataAvailable
        isDeviceLocked = !isProtectedDataAvailable
        
        let status = isDeviceLocked ? "Locked" : "Unlocked"
        statusLabel.text = "Device Status: \(status)"
        
        addEventToHistory("Initial status: Device is \(status)")
        
        os_log("Initial device status: %{public}@", log: logger, type: .info, status)
    }
    
    // MARK: - Notification Handlers
    
    @objc private func deviceDidLock() {
        os_log("Device locked (protected data unavailable)", log: logger, type: .info)
        handleDeviceLock()
    }
    
    @objc private func deviceDidUnlock() {
        os_log("Device unlocked (protected data available)", log: logger, type: .info)
        handleDeviceUnlock()
    }
    
    @objc private func appDidEnterBackground() {
        os_log("App entered background", log: logger, type: .debug)
        
        // Check if device is locked when app goes to background
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            if !UIApplication.shared.isProtectedDataAvailable {
                self?.handleDeviceLock()
            }
        }
    }
    
    @objc private func appWillEnterForeground() {
        os_log("App will enter foreground", log: logger, type: .debug)
        
        // Check if device is unlocked when app comes to foreground
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            if UIApplication.shared.isProtectedDataAvailable && self?.isDeviceLocked == true {
                self?.handleDeviceUnlock()
            }
        }
    }
    
    // MARK: - Event Handlers
    
    private func handleDeviceLock() {
        guard !isDeviceLocked else { return }
        
        isDeviceLocked = true
        lockCount += 1
        
        let currentTime = formatCurrentTime()
        lockTimeLabel.text = "Last Lock Time: \(currentTime)"
        lockCountLabel.text = "Lock Count: \(lockCount)"
        statusLabel.text = "Device Status: Locked"
        
        addEventToHistory("🔒 Device locked at \(currentTime)")
        
        os_log("Device lock event processed - Count: %d", log: logger, type: .info, lockCount)
    }
    
    private func handleDeviceUnlock() {
        guard isDeviceLocked else { return }
        
        isDeviceLocked = false
        unlockCount += 1
        
        let currentTime = formatCurrentTime()
        unlockTimeLabel.text = "Last Unlock Time: \(currentTime)"
        unlockCountLabel.text = "Unlock Count: \(unlockCount)"
        statusLabel.text = "Device Status: Unlocked"
        
        addEventToHistory("🔓 Device unlocked at \(currentTime)")
        
        os_log("Device unlock event processed - Count: %d", log: logger, type: .info, unlockCount)
    }
    
    // MARK: - Action Methods
    
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