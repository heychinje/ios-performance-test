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
    private var mode: TNDriveDetectionMode? = nil
    private var isStarted = false
    
    func getCurrentMode() -> TNDriveDetectionMode? {
        return mode
    }
    
    func getModeString() -> String? {
        return mode?.toText()
    }
    
    func modeToggle(onCompleteion: @escaping (_ errMsg: String?, _ result: Bool) -> Void) {
        if (isInitialized()) {
            onCompleteion("DriveMotionManager: cannot change mode in initialized state.", false)
            return
        }
        let oldMode = mode
        let newMode = mode == TNDriveDetectionMode.auto ? TNDriveDetectionMode.manual : TNDriveDetectionMode.auto
        mode = newMode
        onCompleteion("change mode: \(oldMode?.toText() ?? "nl") -> \(newMode.toText())", true)
    }
    
    func start(onCompleteion: @escaping (_ errMsg: String?, _ result: Bool) -> Void) {
        guard let mode = mode else {
            onCompleteion("the mode is not set yet!", false)
            return
        }
        if (isStarted) {
            onCompleteion("DM has already started.", false)
            return
        }
        if (!isInitialized()) {
            initialize(mode: mode) { [weak self] errMsg, result in
                if (!result) {
                    onCompleteion(errMsg, result)
                    return
                }
                
                if (mode == .auto) {
                    self?.isStarted = true
                    onCompleteion("DM initialized with [\(mode.toText())] mode successfully and in testing...", true)
                } else if (mode == .manual) {
                    onCompleteion("DM initialized with [\(mode.toText())] mode successfully, is going to start...", false)
                    do {
                        let client = try TNDriveMotionService.getDriveMotionClient()
                        try client.startDrive()
                        self?.isStarted = true
                        onCompleteion("DM started with [\(mode.toText())] mode successfully and in testing...", true)
                    } catch {
                        onCompleteion("failed to started with [\(mode.toText())] mode. error: \(error)", false)
                    }
                }
            }
        } else {
            if (!isStarted) {
                guard mode == .manual else {
                    onCompleteion("DM cannot start with [\(mode.toText())] mode", false)
                    return
                }
                
                do {
                    let client = try TNDriveMotionService.getDriveMotionClient()
                    try client.startDrive()
                    isStarted = true
                    onCompleteion("DM started with [\(mode.toText())] mode successfully and in testing...", true)
                } catch {
                    onCompleteion("failed to started with [\(mode.toText())] mode. error: \(error)", false)
                }
            }
        }
    }
    
    func stop(onCompleteion: @escaping (_ errMsg: String?, _ result: Bool) -> Void) {
        guard let mode = mode else {
            onCompleteion("the mode is not set yet!", false)
            return
        }
        
        if (!isInitialized()) {
            onCompleteion("the mode is not initialized yet, no need to stop.", false)
            return
        }
        
        if (!isStarted) {
            onCompleteion("the mode is not started yet, no need to stop.", false)
            return
        }
        
        if (mode == .auto) {
            isStarted = false
            deinitialize()
            onCompleteion("DM stopped with [\(mode.toText())] mode successfully.", true)
        } else if (mode == .manual) {
            do {
                let client = try TNDriveMotionService.getDriveMotionClient()
                try client.stopDrive()
                isStarted = false
                deinitialize()
                onCompleteion("DM stopped with [\(mode.toText())] mode successfully.", true)
            } catch {
                onCompleteion("failed to stop with [\(mode.toText())] mode. error: \(error)", false)
            }
        }
    }
    
    func initManuel(onCompleteion: @escaping (_ errMsg: String?, _ result: Bool) -> Void) {
        guard let mode = mode else {
            onCompleteion("Cannot init manuel due to nil mode.", false)
            return
        }
        
        if (isInitialized()) {
            onCompleteion("Cannot init manuel due to already initialized.", false)
            return
        }
        
        initialize(mode: mode) { errMsg, result in
            if (!result) {
                onCompleteion(errMsg, result)
                return
            }
            onCompleteion("DM initialized with [\(mode.toText())] mode successfully", true)
        }
    }
    
    func deinitManuel(onCompleteion: @escaping (_ errMsg: String?, _ result: Bool) -> Void) {
        guard let mode = mode else {
            onCompleteion("the mode is not set yet!", false)
            return
        }
        
        if (!isInitialized()) {
            onCompleteion("the mode is not initialized yet, no need to stop.", false)
            return
        }
        
        deinitialize()
        onCompleteion("DM deinitialized with [\(mode.toText())] mode successfully", true)
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
        let logSettings = TNLoggerSettings(level: .off, rootPath: "", fileNamePrefix: "")
        return TNDriveMotionSettingsBuilder()
            .isExternalUserIdUsedByForce(true)
            .driveDetectionMode(mode)
            .loggerSettings(logSettings)
            .delegate(delegate)
            .build()
    }
    
    private func initialize(mode: TNDriveDetectionMode, onCompleteion: @escaping (_ errMsg: String?, _ result: Bool) -> Void) {
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
            onCompleteion("DM is initialized successfully!!! mode: \(mode)", true)
        } catch {
            onCompleteion("DriveMotionManager: failed to initialize Drive Motion Service. error: \(error)", false)
        }
    }
    
    private func deinitialize() {
        // it is must, due to internal logic in DM, otherwise a crash will occurre.
        Thread.sleep(forTimeInterval: 0.1)
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
