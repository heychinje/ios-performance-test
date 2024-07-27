//
//  DriveMotionManager.swift
//  PerformanceTest
//
//  Created by Zheng, Haiqiang (Jason) on 2024/7/26.
//

import Foundation
import TelenavDriveMotion
import TelenavDriveMotionAPI

@objcMembers class DriveMotionManager: NSObject {
    private var mode = TNDriveDetectionMode.auto
    
    func getCurrentMode() -> TNDriveDetectionMode {
        return mode
    }
    
    func getModeString() -> String {
        return mode.toText()
    }
    
    func modeToggle() {
        if (!isInitialized()) {
            var newMode = mode
            if (mode == TNDriveDetectionMode.auto) {
                newMode = TNDriveDetectionMode.manual
            } else {
                newMode = TNDriveDetectionMode.auto
            }
            NSLog("DriveMotionManager: change mode: \(mode) -> \(newMode)")
            mode = newMode
        }
    }
    
    func startAutoMode() {
        if (!isInitialized()) {
            initialize { err in
                if (err == nil) {
                    NSLog("DriveMotionManager: DriveMotion is started in Auto Mode")
                }
            }
        }
    }
    
    func stopAutoMode() {
        if (isInitialized()) {
            deinitialize()
            NSLog("DriveMotionManager: DriveMotion is stopped in Auto Mode")
        }
    }
    
    func startManuelMode() {
        if (!isInitialized()) {
            initialize { err in
                if (err == nil) {
                    do {
                        let client = try TNDriveMotionService.getDriveMotionClient()
                        try client.startDrive()
                        NSLog("DriveMotionManager: DriveMotion is started in Manuel Mode")
                    } catch {
                        NSLog("DriveMotionManager: failed to start drive. error: \(error)")
                    }
                }
            }
        }
    }
    
    func stopManuelMode() {
        if (isInitialized()) {
            do {
                let client = try TNDriveMotionService.getDriveMotionClient()
                try client.stopDrive()
                NSLog("DriveMotionManager: DriveMotion is started in Manuel Mode")
            } catch {
                NSLog("DriveMotionManager: failed to start drive. error: \(error)")
            }

            // it is must, due to internal logic in DM, otherwise a crash will occurre.
            Thread.sleep(forTimeInterval: 0.1)
            deinitialize()
        }
    }
    
    func isInitialized() -> Bool {
        return TNDriveMotionService.isInitialized()
    }
    
    private func buildOptions() -> TelenavDriveMotionAPI.TNSDKOptions? {
        let apiKey = Bundle.main.object(forInfoDictionaryKey: "DM_API_KEY") as? String ?? ""
        let apiSecret = Bundle.main.object(forInfoDictionaryKey: "DM_API_SECRET") as? String ?? ""
        let endPoint = Bundle.main.object(forInfoDictionaryKey: "DM_END_POINT") as? String ?? ""
        let userId = Bundle.main.object(forInfoDictionaryKey: "DM_USER_ID") as? String ?? ""
        let deviceGuid = Bundle.main.object(forInfoDictionaryKey: "DM_DEVICE_ID") as? String ?? ""
        return TNSDKOptionsBuilder()
            .apiKey(apiKey)
            .apiSecret(apiSecret)
            .cloudEndPoint("https://\(endPoint)")
            .appInfo(name: "Scout_test", version: "999.999.999")
            .userId(userId)
            .deviceGuid(deviceGuid)
            .build()
    }
    
    private func buildSettings(mode: TNDriveDetectionMode, delegate: TNDriveMotionDelegate) -> TelenavDriveMotionAPI.TNDriveMotionSettings? {
        return TNDriveMotionSettingsBuilder()
            .isExternalUserIdUsedByForce(true)
            .driveDetectionMode(mode)
            .delegate(delegate)
            .build()
    }
    
    private func initialize(onCompleteion: @escaping (_ error: Error?) -> Void) {
        guard let options = buildOptions() else {
            NSLog("DriveMotionManager: failed to build options")
            return
        }
        guard let settings = buildSettings(mode: mode, delegate: DriveMotionDelegate()) else {
            NSLog("DriveMotionManager: failed to build settings")
            return
        }
        
        do {
            try TNDriveMotionService.initialize(
                sdkOptions: options,
                driveMotionSettings: settings
            )
            onCompleteion(nil)
        } catch {
            NSLog("DriveMotionManager: failed to initialize Drive Motion Service. error: \(error)")
            onCompleteion(error)
        }
    }
    
    private func deinitialize() {
        do {
            try TNDriveMotionService.shutdown()
        } catch {
            NSLog("DriveMotionManager: failed to stop auto mode. error: \(error)")
        }
    }
}

extension TNDriveDetectionMode {
    func toText() -> String {
        return self == .auto ? "AUTO" : "MANUEL"
    }
}
