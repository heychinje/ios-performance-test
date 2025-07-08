//
//  Matrix.swift
//  PerformanceTest
//
//  Created by Zheng, Haiqiang (Jason) on 2024/10/3.
//

import Foundation
import Accelerate

struct Matrix {
    static var Empty = Matrix(rows: 0, cols: 0, grid: [])
    
    let rows: Int
    let cols: Int
    var grid: [Double]
    
    init(rows: Int, cols: Int, grid: [Double]) {
        assert(rows >= 0 && cols >= 0 && grid.count == rows * cols, "Grid size does not match matrix dimensions.")
        self.rows = rows
        self.cols = cols
        self.grid = grid
    }
    
    init(rows: Int, cols: Int) {
        let grid = Array(repeating: 0.0, count: rows * cols)
        self.init(rows: rows, cols: cols, grid: grid)
    }
    
    subscript(row: Int, col: Int) -> Double {
        get {
            return grid[row * cols + col]
        }
        set {
            grid[row * cols + col] = newValue
        }
    }
    
    static func +(lhs: Matrix, rhs: Matrix) -> Matrix {
        assert(lhs.rows == rhs.rows && lhs.cols == rhs.cols, "Matrix dimensions must agree")
        var result = lhs.grid
        vDSP_vaddD(lhs.grid, 1, rhs.grid, 1, &result, 1, vDSP_Length(lhs.grid.count))
        return Matrix(rows: lhs.rows, cols: lhs.cols, grid: result)
    }
    
    static func -(lhs: Matrix, rhs: Matrix) -> Matrix {
        assert(lhs.rows == rhs.rows && lhs.cols == rhs.cols, "Matrix dimensions must agree")
        var result = lhs.grid
        vDSP_vsubD(rhs.grid, 1, lhs.grid, 1, &result, 1, vDSP_Length(lhs.grid.count))
        return Matrix(rows: lhs.rows, cols: lhs.cols, grid: result)
    }
    
    static func *(lhs: Matrix, rhs: Matrix) -> Matrix {
        assert(lhs.cols == rhs.rows, "Matrix dimensions must agree for multiplication")
        var result = [Double](repeating: 0.0, count: lhs.rows * rhs.cols)
        vDSP_mmulD(lhs.grid, 1, rhs.grid, 1, &result, 1, vDSP_Length(lhs.rows), vDSP_Length(rhs.cols), vDSP_Length(lhs.cols))
        return Matrix(rows: lhs.rows, cols: rhs.cols, grid: result)
    }
    
    static func ==(lhs: Matrix, rhs: Matrix) -> Bool {
        // First, check if the dimensions are the same
        guard lhs.rows == rhs.rows && lhs.cols == rhs.cols else {
            return false
        }
        // Then, compare the grid values
        return lhs.grid == rhs.grid
    }
    
    static func !=(lhs: Matrix, rhs: Matrix) -> Bool {
        return !(lhs == rhs)
    }
    
    static func identity(size: Int) -> Matrix {
        var identityGrid = [Double](repeating: 0.0, count: size * size)
        for i in 0..<size {
            identityGrid[i * size + i] = 1.0
        }
        return Matrix(rows: size, cols: size, grid: identityGrid)
    }
    
    var transposed: Matrix {
        var result = [Double](repeating: 0.0, count: rows * cols)
        vDSP_mtransD(grid, 1, &result, 1, vDSP_Length(cols), vDSP_Length(rows))
        return Matrix(rows: cols, cols: rows, grid: result)
    }
    
    // Inverts the matrix using LAPACK routines from the Accelerate framework
    func inverse() -> Matrix? {
        guard rows == cols else {
            print("Matrix is not square, cannot invert")
            return nil
        }

        var inMatrix = grid  // Copy matrix data, LAPACK modifies in place
        var N = __CLPK_integer(rows)
        var pivots = [__CLPK_integer](repeating: 0, count: rows)
        var workspace = [Double](repeating: 0.0, count: rows)
        var error: __CLPK_integer = 0

        // LU factorization using LAPACK's dgetrf_
        withUnsafeMutablePointer(to: &N) { N in
            dgetrf_(N, N, &inMatrix, N, &pivots, &error)
        }

        guard error == 0 else {
            print("LU factorization failed, matrix is singular")
            return nil
        }

        // Inversion using LAPACK's dgetri_
        withUnsafeMutablePointer(to: &N) { N in
            dgetri_(N, &inMatrix, N, &pivots, &workspace, N, &error)
        }

        guard error == 0 else {
            print("Matrix inversion failed")
            return nil
        }

        return Matrix(rows: rows, cols: cols, grid: inMatrix)
    }
    
    func copy() -> Matrix {
        return Matrix(rows: rows, cols: cols, grid: grid)
    }
}
