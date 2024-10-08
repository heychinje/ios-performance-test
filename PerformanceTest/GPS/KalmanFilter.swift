//
//  KalmanFilteringAlgorithm.swift
//  PerformanceTest
//
//  Created by Zheng, Haiqiang (Jason) on 2024/10/5.
//

import Foundation
import CoreLocation
import CoreMotion

///
/// 0. Equations of motion model, 1 radians represents 111_000 meters, MPR = 111_000
///
/// ** Lat = Lat_old + (speed x cos(course) x dt + 0.5 x lat_acceleration x dt^2) / 111000 **
/// or  ** Lat = Lat_old + speed x cos(course) x dt / 111000 + 0.5 x lat_acceleration x dt^2 / 111000**
///
/// ** Lon = Lon_old - (speed x sin(course) x dt + 0.5 x lon_acceleration x dt^2) / (111000 x cos(lat)) **
/// or ** Lon = Lon_old -  speed x sin(course) x dt / (111000 x cos(lat)) - 0.5 x lon_acceleration x dt^2 / (111000 x cos(lat)) **
///
/// ** Alt = Alt_old **
///
/// ** Speed = Speed_old + lat_acceleration / cos(course) x dt **
///
/// ** Course = Course_old **
///
/// 1. Define state vectors matrix: **X, 7 x 1**
///
/// [0,0] **lat**: latitude
/// [1,0] **lon**: longitude
/// [2,0] **alt**: altitude
/// [3,0] **speed**:  velocity in m/s
/// [4,0] **course**: location bearing, 0 is the true North in range 0 ~ 359, clockwise.
/// [5,0] **lat acceleration**: latitude orientation acceleration in m/s^2
/// [6,0] **lon acceleration**: longitude orientation acceleration in m/s^2
///
/// 2. Define state transition matrix: **F, 7 x 7**
///      [ ,0]    [ ,1]    [ ,2]    [ ,3]                                                        [ ,4]    [ ,5]                        [ ,6]
/// [0, ]    1          0          0           cos(course)⋅dt/111000                             0          0.5dt^2/111000        0
/// [1, ]    0          1          0           -sin(course)⋅dt/(111000xcos(lat))             0          0                              0.5dt^2/(111000xcos(lat))
/// [2, ]    0          0          1           0                                                               0          0                              0
/// [3, ]    0          0          0           1                                                               0          dt/cos(course)         0
/// [4, ]    0          0          0           0                                                               1          0                              0
/// [5, ]    0          0          0           0                                                               0          1                              0
/// [6, ]    0          0          0           0                                                               0          0                              1
///
/// 3. Define process noise matrix: **Q, 7 x 7**
///      [ ,0]    [ ,1]    [ ,2]    [ ,3]    [ ,4]    [ ,5]    [ ,6]
/// [0, ]      1          0          0           0          0           0           0
/// [1, ]      0          1          0           0          0           0           0
/// [2, ]      0          0          9           0          0           0           0
/// [3, ]      0          0          0           0.01     0           0           0
/// [4, ]      0          0          0           0          25         0           0
/// [5, ]      0          0          0           0          0           2.25      0
/// [6, ]      0          0          0           0          0           0           2.25
/// Notes:
/// lat/lon sigma: 1 m, sigma^2 = 1
/// alt sigma: 3 m, sigma^2 = 9
/// speed sigma: 0.1 m/s, sigma^2 = 0.01
/// course sigma: 5 degrees, sigma^2 = 25
/// accelerationX/Y sigma: 1.5 m/s^2, sigma^2 = 2.25
///
/// These sigma values might be changed based on the current system state. Right now we suppose they are constant
///
/// 4. Define measurement matrix: **H, 7 x 7**. Usually, it is a constant.
///      [ ,0]    [ ,1]    [ ,2]    [ ,3]    [ ,4]    [ ,5]    [ ,6]
/// [0, ]      1          0          0           0          0           0           0
/// [1, ]      0          1          0           0          0           0           0
/// [2, ]      0          0          1           0          0           0           0
/// [3, ]      0          0          0           1          0           0           0
/// [4, ]      0          0          0           0          1           0           0
/// [5, ]      0          0          0           0          0           1           0
/// [6, ]      0          0          0           0          0           0           1
///
/// 5. Define measurement noise matrix: **R, 7 x 7**
///      [ ,0]    [ ,1]    [ ,2]    [ ,3]    [ ,4]    [ ,5]    [ ,6]
/// [0, ]   hA^2        0          0           0          0           0           0
/// [1, ]      0       hA^2        0           0          0           0           0
/// [2, ]      0          0        vA^2        0          0           0           0
/// [3, ]      0          0           0       sA^2        0           0           0
/// [4, ]      0          0           0           0       cA^2        0           0
/// [5, ]      0          0           0           0          0           2.25      0
/// [6, ]      0          0           0           0          0           0           2.25
/// Notes:
/// The GPS APIs can read all noise values except for  **lat_acceleration** and **lon_acceleration**,
/// so we supposed the acceleration noise is 1.5 m/s^2. That means, sigma = 1.5 and sigma^2 = 2.25
///
/// 6. Define process noise matrix: **P, **, the initial value is the same with **Q**, it will be updated in each of the next iterators.
///      [ ,0]    [ ,1]    [ ,2]    [ ,3]    [ ,4]    [ ,5]    [ ,6]
/// [0, ]      1          0          0           0          0           0           0
/// [1, ]      0          1          0           0          0           0           0
/// [2, ]      0          0          9           0          0           0           0
/// [3, ]      0          0          0           0.01     0           0           0
/// [4, ]      0          0          0           0          25         0           0
/// [5, ]      0          0          0           0          0           2.25      0
/// [6, ]      0          0          0           0          0           0           2.25
/// Notes:
/// lat/lon sigma: 1 m, sigma^2 = 1
/// alt sigma: 3 m, sigma^2 = 9
/// speed sigma: 0.1 m/s, sigma^2 = 0.01
/// course sigma: 5 degrees, sigma^2 = 25
/// accelerationX/Y sigma: 1.5 m/s^2, sigma^2 = 2.25
///
struct KalmanFilter {
    private var timestamp: Date = Date()
    
    // state vector count
    private let stateCount = 7
    
    // metters per radina
    private let MPR = 111_000.0
    
    // state vectors matrix
    private var X: Matrix = .Empty
    
    // state transition matrix: from the current state to the next state.
    private var F: Matrix = .Empty
    
    // measurement model matrix
    private var H: Matrix = .Empty
    
    // state covariance matrix
    private var P: Matrix = .Empty
    
    // process noise covariance matrix
    private var Q: Matrix = .Empty
    
    // measurement noise covariance matrix
    private var R: Matrix = .Empty
    
    var isInitialized: Bool {
        return X != .Empty
    }
    
    var location: CLLocation {
        let hA = sqrt(P[0,0])
        let vA = sqrt(P[2,2])
        let sA = sqrt(P[3,3])
        let cA = sqrt(P[4,4])
        return CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: X[0,0], longitude: X[1,0]),
            altitude: X[2,0],
            horizontalAccuracy: hA,
            verticalAccuracy: vA,
            course: X[4,0],
            courseAccuracy: cA,
            speed: X[3,0],
            speedAccuracy: sA,
            timestamp: timestamp
        )
    }
    
    mutating func initialize(_ loc : CLLocation, _ a: WorldAcceleration) {
        guard !isInitialized else { return }
        let hA: Double = loc.horizontalAccuracy
        let vA: Double = loc.verticalAccuracy
        let sA: Double = loc.speedAccuracy
        let cA: Double = loc.courseAccuracy
        
        timestamp = Date()

        /// 1. Define state vectors matrix: **X, 7 x 1**
        X = Matrix.init(
            rows: stateCount,
            cols: 1,
            grid: [
                loc.coordinate.latitude,
                loc.coordinate.longitude,
                loc.altitude,
                loc.speed,
                loc.course,
                a.latAcceleration,
                a.lonAcceleration
            ]
        )
    
        /// 2. Define state transition matrix: **F, 7 x 7**
        F = Matrix.identity(size: stateCount)
        correctF(dt: 0.1)
        
        /// 3. Define process noise matrix: **Q, 7 x 7**
        Q = Matrix.identity(size: stateCount)
        correctQ()
        
        /// 4. Define measurement matrix: **H, 7 x 7**. Usually, it is a constant.
        H = Matrix.identity(size: stateCount)
        
        /// 5. Define measurement noise matrix: **R, 7 x 7**
        R = Matrix.identity(size: stateCount)
        correctR(hA: hA, vA: vA, sA: sA, cA: cA)
        
        /// 6. Define process noise matrix: **P, **, the initial value is the same with **Q**, it will be updated in each of the next iterators.
        P = Q.copy()
    }
    
    mutating func predict(_ dt: TimeInterval, _ a : WorldAcceleration) {
        // using the current acceleration to predict the next time point state after dt
        X[5, 0] = a.latAcceleration
        X[6, 0] = a.lonAcceleration

        // update state transition matrix
        correctF(dt: dt)

        // predict the next state
        X = F * X

        // update state covariance matrix
        let I = Matrix.identity(size: stateCount)
        P = F * P * F.transposed + Q
        
        // update timestamp
        timestamp = Date()
    }
    
    mutating func update(_ location : CLLocation, _ a: WorldAcceleration) {
        let Z = Matrix.init(
            rows: stateCount,
            cols: 1,
            grid: [
                location.coordinate.latitude,
                location.coordinate.longitude,
                location.altitude,
                location.speed,
                location.course,
                a.latAcceleration,
                a.lonAcceleration
            ]
        )
        
        // Step 1: Compute the measurement residual
        let y = Z - (H * X)
        
        // Step 2: Compute the Kalman Gain
        let K = computeKalmanGain()
        guard K != .Empty else { return }
        
        // Step 3: Update the state estimate
        X = X + (K * y)
        
        // Step 4: Update the covariance estimate
        let I = Matrix.identity(size: X.rows)
        P = (I - K * H) * P
        
        // update timestamp
        timestamp = Date()
    }
    
    private func computeKalmanGain() -> Matrix {
        let HT = H.transposed
        let S = (H * P * HT) + R
        guard let S_inv = S.inverse() else {
            return .Empty
        }
        let K = P * HT * S_inv
        return K
    }
    

    private mutating func correctF(dt: Double) {
        let lat = X[0, 0]
        let course = X[4, 0]
        let courseRadinas = course.inRadians
        let latRadinas = lat.inRadians
        let sinCourse = sin(courseRadinas)
        let cosCourse = cos(courseRadinas)
        let cosLat = cos(latRadinas)
        
        let inPoleArea = abs(cosLat) < 1e-10
        let parallelToEquator = abs(cosCourse) < 1e-10
        
        F[0,3] = cosCourse * dt / MPR
        F[0,5] = 0.5 * dt * dt / MPR
        F[1,3] = inPoleArea ? 0 : -sinCourse * dt / (MPR * cosLat)
        F[1,6] = inPoleArea ? 0 : 0.5 * dt * dt / (MPR * cosLat)
        F[3,5] = parallelToEquator ? dt : dt / cosCourse
    }

    
    private mutating func correctQ() {
        Q[2,2] = 9
        Q[3,3] = 0.01
        Q[4,4] = 25
        Q[5,5] = 2.25
        Q[6,6] = 2.25
    }
    
    private mutating func correctR(hA: Double, vA: Double, sA: Double, cA: Double) {
        if hA >= 0 { R[0,0] = hA * hA }
        if hA >= 0 { R[1,1] = hA * hA }
        if vA >= 0 { R[2,2] = vA * vA }
        if sA >= 0 { R[3,3] = sA * sA }
        if cA >= 0 { R[4,4] = cA * cA }
    }
}

private extension Double {
    var inRadians: Double {
        return self * .pi / 180
    }
}

struct WorldAcceleration {
    let latAcceleration: Double // m/s^2
    let lonAcceleration: Double // m/s^2
    
    // the gravity of Earth
    private static let g = 9.81
    
    static func from(deviceMotion motion: CMDeviceMotion) -> WorldAcceleration {
        let D = Matrix.init(
            rows: 3,
            cols: 1,
            grid: [
                motion.userAcceleration.x,
                motion.userAcceleration.y,
                motion.userAcceleration.z
            ]
        )
        
        let R = Matrix.init(
            rows: 3,
            cols: 3,
            grid: [
                motion.attitude.rotationMatrix.m11, motion.attitude.rotationMatrix.m12, motion.attitude.rotationMatrix.m13,
                motion.attitude.rotationMatrix.m21, motion.attitude.rotationMatrix.m22, motion.attitude.rotationMatrix.m23,
                motion.attitude.rotationMatrix.m31, motion.attitude.rotationMatrix.m32, motion.attitude.rotationMatrix.m33
            ]
        )
        
        let A = R * D
        return WorldAcceleration(latAcceleration: A[1,0] * g, lonAcceleration: A[0,0] * g)
    }
}
