//
//  MainUIViewControllerRepresentable.swift
//  PerformanceTest
//
//  Created by Zheng, Haiqiang (Jason) on 2024/7/4.
//

import Foundation
import SwiftUI

struct MainUIViewControllerRepresentable: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController
    
    func makeUIViewController(context: Context) -> UIViewController {
        return UINavigationController(rootViewController: MainUIViewController())
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
}
