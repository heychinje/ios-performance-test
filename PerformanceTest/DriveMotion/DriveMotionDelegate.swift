//
//  DriveMotionDelegate.swift
//  PerformanceTest
//
//  Created by Zheng, Haiqiang (Jason) on 2024/7/26.
//

import Foundation
import TelenavDriveMotion
import TelenavDriveMotionAPI

@objcMembers class DriveMotionDelegate: NSObject, TNDriveMotionDelegate {
    func onDriveStart(_ event: TelenavDriveMotionAPI.TNDriveStartEvent) throws {
        NSLog("DriveMotionDelegate.onDriveStart: \(event)")
    }
    
    func onDriveEnd(_ event: TelenavDriveMotionAPI.TNDriveEndEvent) throws {
        NSLog("DriveMotionDelegate.onDriveEnd: \(event)")
    }
    
    func onDriveEventDetected(_ event: TelenavDriveMotionAPI.TNDriveEvent) throws {
        NSLog("DriveMotionDelegate.onDriveEventDetected: \(event)")
    }
    
    func onDriveScoreUpdated(_ event: TelenavDriveMotionAPI.TNDriveScoreEvent) throws {
        NSLog("DriveMotionDelegate.onDriveScoreUpdated: \(event)")
    }
    
    func onDriveAnalyzed(_ event: TelenavDriveMotionAPI.TNDriveAnalyzedEvent) throws {
        NSLog("DriveMotionDelegate.onDriveAnalyzed: \(event)")
    }
}
