//
//  TestItem.swift
//  PerformanceTest
//
//  Created by Zheng, Haiqiang (Jason) on 2025/7/8.
//




let testItems: [TestItem] = [
    TestItem(title: "OpenGL", viewControllerClass: OpenGLUIViewController.self, needsTestRecords: true),
    TestItem(title: "Metal", viewControllerClass: MetalUIViewController.self, needsTestRecords: true),
    TestItem(title: "DriveMotion", viewControllerClass: DriveMotionViewController.self),
    TestItem(title: "APM", viewControllerClass: APMViewController.self),
    TestItem(title: "GPS", viewControllerClass: GpsUIViewController.self),
    TestItem(title: "Video", viewControllerClass: AVPlayerUIViewController.self),
    TestItem(title: "PhoneCall", viewControllerClass: PhoneCallViewController.self),
    TestItem(title: "DeviceLock", viewControllerClass: DeviceLockViewController.self)
]








/// Test item configuration
struct TestItem {
    let title: String
    let viewControllerClass: UIViewController.Type
    let needsTestRecords: Bool
    
    init(title: String, viewControllerClass: UIViewController.Type, needsTestRecords: Bool = false) {
        self.title = title
        self.viewControllerClass = viewControllerClass
        self.needsTestRecords = needsTestRecords
    }
}

