//
//  GpsUIViewController.swift
//  PerformanceTest
//
//  Created by Zheng, Haiqiang (Jason) on 2024/9/29.
//

import Foundation
import CoreLocation
import CoreMotion

class GpsUIViewController: UIViewController, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    private var mMgr = CMMotionManager()
    private var kf = KalmanFilter()
    private var gpsFilePath: URL = URL(fileURLWithPath: "")
    private var logFilePath: URL = URL(fileURLWithPath: "")
    
    override func viewDidLoad() {
        configLocationManager()
        configMotionManager()
        configFiles()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        startUpdateLocation()
        startUpdateAcceleration()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
//        stopUpdateLocation()
//        stopUpdateAcceleration()
    }
    
    private func configLocationManager() {
        locationManager.delegate = self
        locationManager.distanceFilter = 0
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.activityType = .automotiveNavigation
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.allowsBackgroundLocationUpdates = true
    }
    
    private func startUpdateLocation() {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    private func stopUpdateLocation() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    
    private func configMotionManager() {
        guard mMgr.isAccelerometerAvailable else { return }
        mMgr.accelerometerUpdateInterval = 0.1
    }
    
    private func startUpdateAcceleration() {
        mMgr.startDeviceMotionUpdates()
    }
    
    private func stopUpdateAcceleration() {
        if mMgr.isDeviceMotionActive {
            mMgr.stopDeviceMotionUpdates()
        }
    }
    
    private func configFiles() {
        // Prepare date formatter for today's date as the file name
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        gpsFilePath = documentsDirectory.appendingPathComponent("\(dateFormatter.string(from: Date())).csv")
        logFilePath = documentsDirectory.appendingPathComponent("\(dateFormatter.string(from: Date())).log")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        log("onUpdate: locations: \(locations)")
        guard let location = locations.last else { return }
        guard let deviceMotion = mMgr.deviceMotion else { return }
        if kf.isInitialized {
            kf.update(location, WorldAcceleration.from(deviceMotion: deviceMotion))
            let rawLoc = location
            let kfLoc = kf.location
            appendCSV(
                to: gpsFilePath.path,
                row: [
                    "\(rawLoc.timestamp)",
                    "\(rawLoc.coordinate.latitude)",
                    "\(rawLoc.coordinate.longitude)",
                    "\(rawLoc.altitude)",
                    "\(rawLoc.horizontalAccuracy)",
                    "\(rawLoc.verticalAccuracy)",
                    "\(rawLoc.speed)",
                    "\(rawLoc.speedAccuracy)",
                    "\(rawLoc.course)",
                    "\(rawLoc.courseAccuracy)",
                    "\(kfLoc.timestamp)",
                    "\(kfLoc.coordinate.latitude)",
                    "\(kfLoc.coordinate.longitude)",
                    "\(kfLoc.altitude)",
                    "\(kfLoc.horizontalAccuracy)",
                    "\(kfLoc.verticalAccuracy)",
                    "\(kfLoc.speed)",
                    "\(kfLoc.speedAccuracy)",
                    "\(kfLoc.course)",
                    "\(kfLoc.courseAccuracy)"
                ]
            )
        } else {
            kf.initialize(location, WorldAcceleration.from(deviceMotion: deviceMotion))
            appendCSV(
                to: gpsFilePath.path, 
                row: [
                "raw_timestamp",
                "raw_lat",
                "raw_lon",
                "raw_alt",
                "raw_hA",
                "raw_vA",
                "raw_speed",
                "raw_sA",
                "raw_course",
                "raw_cA",
                "kf_timestamp",
                "kf_lat",
                "kf_lon",
                "kf_alt",
                "kf_hA",
                "kf_vA",
                "kf_speed",
                "kf_sA",
                "kf_course",
                "kf_cA"
                ]
            )
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        log("onUpdate: heading: \(newHeading)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        log("onError: locations: \(error)")
    }
    
    func cMMotionManager(didFailWithError error: any Error) {
        log("onError: motion: \(error)")
    }
    
    private func log(_ msg: String) {
        print("LocationManager: \(msg)")
        log2File(msg: msg)
    }
    
    func appendCSV(to filePath: String, data: [[String]]) {
        // Prepare the CSV formatted content
        let csvContent = data.map { row in
            row.map { value in
                // Escape double quotes within fields
                let escapedValue = value.replacingOccurrences(of: "\"", with: "\"\"")
                // Surround each field with double quotes
                return "\"\(escapedValue)\""
            }.joined(separator: ",")
        }.joined(separator: "\n") + "\n"  // Add newline at the end
        
        // Convert the content into Data for appending to the file
        guard let csvData = csvContent.data(using: .utf8) else { return }
        
        // Get the file URL
        let fileURL = URL(fileURLWithPath: filePath)
        
        // Check if the file exists, if not create it
        do {
            if !FileManager.default.fileExists(atPath: filePath) {
                try csvData.write(to: fileURL)
            } else {
                // Open the file for appending
                let fileHandle = try FileHandle(forWritingTo: fileURL)
                defer { fileHandle.closeFile() }
                
                // Seek to the end of the file
                fileHandle.seekToEndOfFile()
                
                // Write the data to the file
                fileHandle.write(csvData)
            }
        } catch {
            // do nothing
        }
    }
    
    func appendCSV(to filePath: String, row: [String]) {
        // Prepare the CSV formatted content for a single row
        let csvContent = row.map { value in
            // Escape double quotes within fields
            let escapedValue = value.replacingOccurrences(of: "\"", with: "\"\"")
            // Surround each field with double quotes
            return "\"\(escapedValue)\""
        }.joined(separator: ",") + "\n"  // Add newline at the end

        // Convert the content into Data for appending to the file
        guard let csvData = csvContent.data(using: .utf8) else { return }
        
        // Get the file URL
        let fileURL = URL(fileURLWithPath: filePath)
        
        // Check if the file exists, if not create it
        do {
            if !FileManager.default.fileExists(atPath: filePath) {
                try csvData.write(to: fileURL)
            } else {
                // Open the file for appending
                let fileHandle = try FileHandle(forWritingTo: fileURL)
                defer { fileHandle.closeFile() }
                
                // Seek to the end of the file
                fileHandle.seekToEndOfFile()
                
                // Write the data to the file
                fileHandle.write(csvData)
            }
        } catch {
            // Handle error (optional)
            print("Error writing to file: \(error)")
        }
    }
    
    func log2File(msg: String) {
        // Prepare the log message with a timestamp
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        let timestamp = timeFormatter.string(from: Date())
        let logMessage = "[\(timestamp)] \(msg)\n"
        
        guard let logData = logMessage.data(using: .utf8) else { return }
        
        do {
            if !FileManager.default.fileExists(atPath: logFilePath.path) {
                // If the file doesn't exist, create it with initial content
                try logData.write(to: logFilePath)
            } else {
                // If the file exists, append the log message
                let fileHandle = try FileHandle(forWritingTo: logFilePath)
                defer { fileHandle.closeFile() }
                fileHandle.seekToEndOfFile()
                fileHandle.write(logData)
            }
        } catch {
            // do nothing
        }
    }
}

