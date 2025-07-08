//
//  PhoneCallViewController.swift
//  PerformanceTest
//
//  Created by Zheng, Haiqiang (Jason) on 2025/6/9.
//

import UIKit
import CallKit
import os.log

/// A view controller that monitors and displays phone call status
class PhoneCallViewController: UIViewController {
    
    // MARK: - Properties
    
    /// CallKit observer to monitor call state changes
    private let callObserver = CXCallObserver()
    
    /// UI elements to display call status
    private let statusLabel = UILabel()
    private let startTimeLabel = UILabel()
    private let endTimeLabel = UILabel()
    
    /// Call tracking properties
    private var callStartTime: Date?
    private var isIncomingCall = false
    
    /// Logger for tracking call events
    private let logger = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.performance.test", category: "PhoneCall")
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        os_log("PhoneCallViewController initialized", log: logger, type: .info)
        setupUI()
        setupCallObserver()
    }
    
    deinit {
        os_log("PhoneCallViewController deinitialized", log: logger, type: .info)
    }
    
    // MARK: - Setup Methods
    
    /// Sets up the CallKit observer to monitor call state changes
    private func setupCallObserver() {
        callObserver.setDelegate(self, queue: .main)
    }
    
    /// Sets up the user interface elements
    private func setupUI() {
        view.backgroundColor = .white
        
        // Add title label
        let titleLabel = UILabel()
        titleLabel.text = "Phone Call Test"
        titleLabel.textAlignment = .center
        titleLabel.font = .boldSystemFont(ofSize: 20)
        view.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        // Status label to show current call state
        statusLabel.text = "Call Status: No Call"
        statusLabel.textAlignment = .center
        view.addSubview(statusLabel)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        // Start time label to show when call started
        startTimeLabel.text = "Start Time: -"
        startTimeLabel.textAlignment = .center
        view.addSubview(startTimeLabel)
        startTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            startTimeLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
            startTimeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        // End time label to show when call ended
        endTimeLabel.text = "End Time: -"
        endTimeLabel.textAlignment = .center
        view.addSubview(endTimeLabel)
        endTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            endTimeLabel.topAnchor.constraint(equalTo: startTimeLabel.bottomAnchor, constant: 20),
            endTimeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        // Add back button to return to previous screen
        let backButton = UIButton(type: .system)
        backButton.setTitle("Back", for: .normal)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        view.addSubview(backButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: endTimeLabel.bottomAnchor, constant: 40),
            backButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        os_log("UI setup completed", log: logger, type: .debug)
    }
    
    // MARK: - Action Methods
    
    /// Handles back button tap to return to previous screen
    @objc private func backButtonTapped() {
        os_log("Back button tapped", log: logger, type: .info)
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Helper Methods
    
    /// Updates the call status display and logs call events
    /// - Parameters:
    ///   - isConnected: Whether the call is currently connected
    ///   - isEnded: Whether the call has ended
    private func updateCallStatus(_ isConnected: Bool, _ isEnded: Bool = false) {
        let callType = isIncomingCall ? "Incoming" : "Outgoing"
        let status: String
        
        // Determine the appropriate status message based on call state
        if isEnded {
            if isConnected {
                status = "\(callType) Call Ended"
            } else {
                status = "Missed Call"
            }
        } else if isConnected {
            status = "\(callType) Call Connected"
        } else {
            status = "\(callType) Call Ringing"
        }
        
        statusLabel.text = "Call Status: \(status)"
        
        os_log("Call status updated - Type: %{public}@, Connected: %{public}d, Ended: %{public}d", 
               log: logger, 
               type: .info,
               callType,
               isConnected,
               isEnded)
        
        // Handle call timing
        if isConnected && callStartTime == nil {
            // Record call start time
            callStartTime = Date()
            let startTimeStr = formatTime(callStartTime!)
            startTimeLabel.text = "Start Time: \(startTimeStr)"
            os_log("Call started at %{public}@", log: logger, type: .info, startTimeStr)
        } else if (isEnded || !isConnected) && callStartTime != nil {
            // Record call end time and duration
            let endTime = Date()
            let endTimeStr = formatTime(endTime)
            endTimeLabel.text = "End Time: \(endTimeStr)"
            
            if let startTime = callStartTime {
                let duration = endTime.timeIntervalSince(startTime)
                os_log("Call ended at %{public}@, duration: %.2f seconds", 
                       log: logger, 
                       type: .info,
                       endTimeStr,
                       duration)
            }
            
            // Reset call tracking state
            callStartTime = nil
            isIncomingCall = false
        }
    }
    
    /// Formats a date into a time string
    /// - Parameter date: The date to format
    /// - Returns: A formatted time string in HH:mm:ss format
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

// MARK: - CXCallObserverDelegate

extension PhoneCallViewController: CXCallObserverDelegate {
    /// Handles call state changes from CallKit
    /// - Parameters:
    ///   - callObserver: The call observer that detected the change
    ///   - call: The call object containing the new state
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        os_log("Call state changed - Outgoing: %{public}d, Connected: %{public}d, Ended: %{public}d", 
               log: logger, 
               type: .debug,
               call.isOutgoing,
               call.hasConnected,
               call.hasEnded)
        
        // Detect incoming call
        if !call.isOutgoing && !call.hasConnected {
            isIncomingCall = true
            os_log("Incoming call detected", log: logger, type: .info)
        }
        
        // Handle call end first to ensure correct timing
        if call.hasEnded {
            updateCallStatus(call.hasConnected, true)
        } else if call.hasConnected {
            if call.isOutgoing {
                isIncomingCall = false
            }
            updateCallStatus(true)
        }
    }
}
