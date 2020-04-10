//
//  phaseAnalysis.swift
//  SavingFaceToF
//
//  MIT License
//
//  Copyright (c) 2020 Camilo Rojas, Niels Poulsen, James Korrawat, Zhi Wei Gan
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation
import Accelerate


extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
    var mod2pi: Self {
        let r = self.truncatingRemainder(dividingBy: 2 * .pi)
        return r >= 0 ? r : r + 2 * .pi
    }
}


func peak_amplitude(amplitudes: [Float], center: Int, range: Int) -> Int {
    let first = max(center - range, 0)
    let last = center + range
    let b = Array(amplitudes[first...last].enumerated())
    return first + b.max(by: {$0.1 < $1.1})!.0
}


func phase_values(signal: [Float], n: Int, frequencies: [Double]) -> [Double] {
    
    let (output, fft_real, fft_imag): (DSPSplitComplex?, [Float], [Float]) = fft(signal: signal, n: n)
    let amplitudes = zip(fft_real, fft_imag).map { sqrt(pow($0, 2) + pow($1, 2)) }
    
    let range = 1
    let fs: Double = 44100.0
    let n_d: Double = Double(n)
    let f_centers = frequencies.map { Int(((n_d - 1.0) * $0/fs) + 1.0) }
    let peak_f = f_centers.map{ peak_amplitude(amplitudes: amplitudes, center: $0, range: range) }
    
    let halfN = Int(n / 2)
    var result: [Float] = [Float](repeating: 0, count: halfN)
    vDSP.phase(output!, result: &result)
    let phases_found = peak_f.map { Double(result[$0]) }
    
    return phases_found
}


func distance_estimation(lambda: Double, phi: Double, k: Int) -> Double {
    return (lambda/(2 * Double.pi)) * (phi + 2 * Double.pi * Double(k))
}


let c = 343.0


func phase_shift_distance(frequencies: [Double], phases: [Double], ks: [Int]) -> Double {
    let lambdas = frequencies.map { c/$0 }
    
    var total_dist = 0.0
    var values = 0
    
    for a in 0..<frequencies.count {
        total_dist += distance_estimation(lambda: lambdas[a], phi: phases[a], k: ks[a])
        values += 1
    }
    
    return total_dist/Double(values)
}


func phase_shift_distance_smart(frequencies: [Double], phases: [Double], ks: [Int]) -> Double {
    let lambdas = frequencies.map { c/$0 }
    
    var distances: [Double] = []
    
    for a in 0..<frequencies.count {
        distances.append(distance_estimation(lambda: lambdas[a], phi: phases[a], k: ks[a]))
    }
    
    let mean_distance = distances.reduce(0.0, +)/Double(distances.count)
    var centered_distances: [Double] = []
    
    for d in distances {
        if abs(d - mean_distance) < 10.0 {
            centered_distances.append(d)
        }
    }
    
    return centered_distances.reduce(0.0, +)/Double(distances.count)
}


func phase_shift_distance_smart2(frequencies: [Double], phases: [Double], ks: [Int]) -> Double {
    let lambdas = frequencies.map { c/$0 }
    
    var distances: [Double] = []
    
    for a in 0..<frequencies.count {
        distances.append(distance_estimation(lambda: lambdas[a], phi: phases[a], k: ks[a]))
    }
    
    let median_distance = distances.sorted()[distances.count/2]
    var centered_distances: [Double] = []
    
    for d in distances {
        if abs(d - median_distance) < 10.0 {
            centered_distances.append(d)
        }
    }
    
    return centered_distances.reduce(0.0, +)/Double(distances.count)
}
