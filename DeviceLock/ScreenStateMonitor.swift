//
//  ScreenStateMonitor.swift
//  PerformanceTest
//
//  Created by Zheng, Haiqiang (Jason) on 2025/1/27.
//

import UIKit
import LocalAuthentication
import os.log

/// Protocol for receiving screen state change notifications
protocol ScreenStateMonitorDelegate: AnyObject {
    func screenStateMonitor(_ monitor: ScreenStateMonitor, didDetectLock lockTime: Date)
    func screenStateMonitor(_ monitor: ScreenStateMonitor, didDetectUnlock unlockTime: Date)
    func screenStateMonitor(_ monitor: ScreenStateMonitor, didUpdateAuthStatus isPasscodeSet: Bool, biometricType: LABiometryType, error: Error?)
    func screenStateMonitor(_ monitor: ScreenStateMonitor, didChangeBrightness brightness: CGFloat)
}

/// A reusable class for monitoring device screen lock/unlock states
class ScreenStateMonitor {
    
    // MARK: - Properties
    
    weak var delegate: ScreenStateMonitorDelegate?
    
    /// Current device lock state
    private(set) var isDeviceLocked = false
    
    /// Lock/unlock event counters
    private(set) var lockCount = 0
    private(set) var unlockCount = 0
    
    /// Logger for tracking screen state events
    private let logger = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.performance.test", category: "ScreenStateMonitor")
    
    // MARK: - Lifecycle
    
    init() {
        setupNotifications()
        updateInitialStatus()
        checkAuthenticationStatus()
        os_log("ScreenStateMonitor initialized", log: logger, type: .info)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        os_log("ScreenStateMonitor deinitialized", log: logger, type: .info)
    }
    
    // MARK: - Public Methods
    
    /// Manually refresh authentication status
    func refreshAuthenticationStatus() {
        checkAuthenticationStatus()
    }
    
    /// Get current device state information
    func getCurrentState() -> (isLocked: Bool, lockCount: Int, unlockCount: Int) {
        return (isDeviceLocked, lockCount, unlockCount)
    }
    
    // MARK: - Private Setup Methods
    
    /// Sets up notification observers for device state changes
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
        
        // Listen for brightness changes
        notificationCenter.addObserver(
            self,
            selector: #selector(brightnessDidChange),
            name: UIScreen.brightnessDidChangeNotification,
            object: nil
        )
        
        os_log("Notification observers set up", log: logger, type: .debug)
    }
    
    /// Updates the initial status based on current device state
    private func updateInitialStatus() {
        let isProtectedDataAvailable = UIApplication.shared.isProtectedDataAvailable
        isDeviceLocked = !isProtectedDataAvailable
        
        let status = isDeviceLocked ? "Locked" : "Unlocked"
        os_log("Initial device status: %{public}@", log: logger, type: .info, status)
    }
    
    /// Checks authentication status using LocalAuthentication framework
    private func checkAuthenticationStatus() {
        let context = LAContext()
        var error: NSError?
        let isPasscodeSet = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
        
        // Check biometric availability
        let biometricAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        // Log the authentication status
        let authStatus = isPasscodeSet ? "Passcode/Biometric Set" : "No Passcode Set"
        let biometricStatus = biometricAvailable ? "Biometric Available" : "Biometric Not Available"
        
        if let error = error {
            os_log("Authentication check error: %{public}@", log: logger, type: .error, error.localizedDescription)
        }
        
        os_log("Authentication status checked - Passcode: %{public}@, Biometric: %{public}@", 
               log: logger, type: .info, 
               isPasscodeSet ? "true" : "false",
               biometricAvailable ? "true" : "false")
        
        // Notify delegate
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.screenStateMonitor(self, didUpdateAuthStatus: isPasscodeSet, biometricType: context.biometryType, error: error)
        }
    }
    
    // MARK: - Notification Handlers
    
    @objc private func deviceDidLock() {
        os_log("Device did lock (protected data unavailable)", log: logger, type: .info)
        handleDeviceLock()
    }
    
    @objc private func deviceDidUnlock() {
        os_log("Device did unlock (protected data available)", log: logger, type: .info)
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
        
        // Re-check authentication status when app goes to background
        checkAuthenticationStatus()
    }
    
    @objc private func appWillEnterForeground() {
        os_log("App will enter foreground", log: logger, type: .debug)
        
        // Check if device is unlocked when app comes to foreground
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            if UIApplication.shared.isProtectedDataAvailable && self.isDeviceLocked {
                self.handleDeviceUnlock()
            }
        }
        
        // Re-check authentication status when app comes to foreground
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.checkAuthenticationStatus()
        }
    }
    
    @objc private func brightnessDidChange() {
        let currentBrightness = UIScreen.main.brightness
        
        os_log("📱 Screen brightness changed to: %f", 
               log: logger, type: .info, 
               currentBrightness)
        
        // Log potential lock/unlock indicators based on brightness
        if currentBrightness == 0.0 {
            os_log("🔒 Brightness is 0%% - potential device lock indicator", log: logger, type: .info)
        } else if currentBrightness > 0.0 && !isDeviceLocked {
            os_log("🔓 Brightness is %f%% - device appears to be unlocked", log: logger, type: .debug, currentBrightness * 100)
        }
        
        // Notify delegate
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.screenStateMonitor(self, didChangeBrightness: currentBrightness)
        }
    }
    
    // MARK: - Event Handlers
    
    private func handleDeviceLock() {
        guard !isDeviceLocked else { return }
        
        isDeviceLocked = true
        lockCount += 1
        let lockTime = Date()
        
        os_log("[Lock Status]: Device lock event processed - Count: %d", log: logger, type: .info, lockCount)
        
        // Notify delegate
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.screenStateMonitor(self, didDetectLock: lockTime)
        }
    }
    
    private func handleDeviceUnlock() {
        guard isDeviceLocked else { return }
        
        isDeviceLocked = false
        unlockCount += 1
        let unlockTime = Date()
        
        os_log("[Lock Status]: Device unlock event processed - Count: %d", log: logger, type: .info, unlockCount)
        
        // Notify delegate
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.screenStateMonitor(self, didDetectUnlock: unlockTime)
        }
    }
} 
