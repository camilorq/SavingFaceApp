//
//  tof.swift
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
import SpriteKit

extension Collection where Iterator.Element == Float {
    var argmax: Int {
        guard var maxValue = self.first else { return 0 }
        var maxIndex = 0
        for (index, value) in self.enumerated() {
            if value > maxValue {
                maxValue = value
                maxIndex = index
            }
        }
        return maxIndex
    }

    func normalized() -> [Iterator.Element] {
        guard let maxAbs = self.max(by: { abs($0) < abs($1) }) else { return [] }
        let factor = 1.0 / abs(maxAbs)
        return self.map { $0 * factor }
    }
}

// Replicating Matlab's envelope(x, np, 'peak') function
// https://www.mathworks.com/help/signal/ref/envelope.html#buv65g3-np

// Find local maxima seperated by at least n samples: a little bit of FUNctional programming
func local_maxima_indices(signal: [Float], n: Int, offset: Int) -> [Int] {
    if signal.count == 0 {
        return []
    }
    
    let argmax = signal.argmax
    
    // Subsignal before the absolute maxima of 'signal', starting n samples before the maximum
    let before_end = argmax - n
    var before_signal: [Float] = []
    if before_end > 0 {
        before_signal = Array(signal[0...before_end])
    }
    
    // Subsignal after the absolute maxima of 'signal', starting n samples after the maximum
    let after_start = argmax + n
    var after_signal: [Float] = []
    if after_start < signal.count - 1 {
        after_signal = Array(signal[after_start..<signal.count])
    }
    
    return local_maxima_indices(signal: before_signal, n: n, offset: offset) +
        [argmax + offset] +
        local_maxima_indices(signal: after_signal, n: n, offset: offset + after_start)
}


func chirp_sent(fs: Double, t: Double, frequencies: [Double]) -> [Float] {
    let time_array: [Double] = Array(stride(from: 0.0, through: t - 1/fs, by: 1/fs))
    let chirp = time_array.map {(t: Double) -> Float in
        let amp: Double = 1/Double(frequencies.count)
        var signal_value: Double = 0.0
        for freq in frequencies {
            signal_value += amp * sin(2 * Double.pi * freq * t)
        }
        return Float(signal_value)
    }
    return chirp
}

/**
- Parameters:
   - chirp: The output of chrip_sent
   - micData: A float array of length sampleLength, contains recorded data from AKClipRecorder
 
- Returns:
   - Returns the index where the chirp starts
*/

func chirp_start(chirp: [Float], micData: [Float]) -> Int {
    if #available(iOS 13.0, *) {
        let corr = vDSP.correlate(micData, withKernel: chirp)
        // print(corr)
        // Finding the local maximas seperated by at least n indices
        let times = local_maxima_indices(signal: corr.map { Float($0) }, n: 100, offset: 0)
        // Values associated with the indices
        let values = times.map { corr[$0] }
        // Used to get spline interpolation:
        // https://developer.apple.com/documentation/spritekit/skkeyframesequence
        let spline_generator = SKKeyframeSequence(keyframeValues: values, times: times.map { NSNumber(value: $0) })
        spline_generator.interpolationMode = SKInterpolationMode.spline
        let b = Array(0..<corr.count).map {spline_generator.sample(atTime: CGFloat(Float($0)))!}
        let interpol: [Float] = b as! [Float] //[-1.5, 2.25, 3.6,  0.2, -0.1, -4.3]
        // print(interpol)
        let stride = vDSP_Stride(1)
        let n = vDSP_Length(interpol.count)
        var c: Float = .nan
        var i: vDSP_Length = 0
        vDSP_maxvi(interpol, stride, &c, &i, n)
        
        return Int(i)
    }else{
        return 0
    }
}


func hilbert_envelope(signal: [Float]) -> [Float] {
    // https://stackoverflow.com/questions/37968221/similar-function-envelope-matlab-in-python
    // https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.hilbert.html
    // https://github.com/scipy/scipy/blob/v1.4.1/scipy/signal/signaltools.py#L2012-L2120
    // https://en.wikipedia.org/wiki/Heaviside_step_function
    let n = 4096
    let (_, fft_real, fft_imag): (DSPSplitComplex?, [Float], [Float]) = fft(signal: signal, n: n)
    var h = [Float](repeating: 0, count: n)
    h[0] = 1.0
    for i in 1..<n/2 {
        h[i] = 2.0
    }
    if n % 2 == 0 {
        h[n/2] = 1.0
    }else{
        h[(n+1)/2] = 2.0
    }
    let prod_real = zip(fft_real, h).map(*)
    let prod_imag = zip(fft_imag, h).map(*)
    let (inverseOutputReal, inverseOutputImag) = fft_inverse(signal_real: prod_real, signal_imag: prod_imag, n: n)
    let envelope = zip(inverseOutputReal, inverseOutputImag).map { sqrt(pow($0, 2) + pow($1, 2)) }
    return envelope
}


/**
- Parameters:
   - chirp: The output of chrip_sent
   - micData: A float array of length sample_length, contains recorded data from AKClipRecorder
 
- Returns:
   - Returns the index where the chirp starts, using the hilbert transform
*/

func chirp_start_hilbert(chirp: [Float], micData: [Float]) -> (Int, [Float], [Float]) {
    if #available(iOS 13.0, *) {
        let corr = vDSP.correlate(micData, withKernel: chirp)
        let env = hilbert_envelope(signal: corr)
        return (env.argmax, corr, env)
    } else {
        return (0, [], [])
    }
}


/**
 Sorts chirp start times and returns the median start time.
 
- Parameters:
   - chirpStarts: Integer array containing the indices where the chirp starts in each clip recording
 
- Returns:
   - The median chirp start time
*/

func averageChirpStart(chirpStarts: [Int]) -> Int {
    return chirpStarts.sorted(by: <)[chirpStarts.count / 2]
}
