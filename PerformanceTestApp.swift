//
//  PerformanceTestApp.swift
//  PerformanceTest
//
//  Created by Zheng, Haiqiang (Jason) on 2024/7/3.
//

import SwiftUI

@main
struct PerformanceTestApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}


extension Date {
    
    ///  - dateFormat:  such as (yyyy-MM-dd HH:mm:ss)
    func formatTimeStr(with dateFormat: String) -> String {
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = dateFormat
        return dateformatter.string(from: self)
    }
    
    // HH:mm a
    func dateTimeFormat() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: self)
    }
}
