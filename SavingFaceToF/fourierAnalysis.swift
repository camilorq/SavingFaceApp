//
//  fourierAnalysis.swift
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

func fft(signal: [Float], n: Int) -> (DSPSplitComplex?, [Float], [Float]) {
    
    let halfN = Int(n / 2)
    let log2n = vDSP_Length(log2(Float(n)))
    var output: DSPSplitComplex!
    
    if #available(iOS 13.0, *) {
        guard let fftSetUp = vDSP.FFT(log2n: log2n,
                                      radix: .radix2,
                                      ofType: DSPSplitComplex.self) else {
                                        fatalError("Can't create FFT Setup.")
        }
        var forwardInputReal = [Float](repeating: 0, count: halfN)
        var forwardInputImag = [Float](repeating: 0, count: halfN)
        var forwardOutputReal = [Float](repeating: 0, count: halfN)
        var forwardOutputImag = [Float](repeating: 0, count: halfN)
        
        forwardInputReal.withUnsafeMutableBufferPointer { forwardInputRealPtr in
            forwardInputImag.withUnsafeMutableBufferPointer { forwardInputImagPtr in
                forwardOutputReal.withUnsafeMutableBufferPointer { forwardOutputRealPtr in
                    forwardOutputImag.withUnsafeMutableBufferPointer { forwardOutputImagPtr in
                        
                        // 1: Create a `DSPSplitComplex` to contain the signal.
                        var forwardInput = DSPSplitComplex(realp: forwardInputRealPtr.baseAddress!,
                                                           imagp: forwardInputImagPtr.baseAddress!)
                        
                        // 2: Convert the real values in `signal` to complex numbers.
                        signal.withUnsafeBytes {
                            vDSP.convert(interleavedComplexVector: [DSPComplex]($0.bindMemory(to: DSPComplex.self)),
                                         toSplitComplexVector: &forwardInput)
                        }
                        
                        // 3: Create a `DSPSplitComplex` to receive the FFT result.
                        output = DSPSplitComplex(realp: forwardOutputRealPtr.baseAddress!,
                                                        imagp: forwardOutputImagPtr.baseAddress!)
                        
                        // 4: Perform the forward FFT.
                        fftSetUp.forward(input: forwardInput,
                                         output: &output)
                    }
                }
            }
        }
        
        let output_real: [Float] = forwardOutputReal
        let output_imag: [Float] = forwardOutputImag
        
        return (output, output_real, output_imag)
    }else{
        return (output, [0.0], [0.0])
    }
}

func fft_inverse(signal_real: [Float], signal_imag: [Float], n: Int) -> ([Float], [Float]) {

    let halfN = Int(n / 2)
    let log2n = vDSP_Length(log2(Float(n)))
    
    if #available(iOS 13.0, *) {
        guard let fftSetUp = vDSP.FFT(log2n: log2n,
                                      radix: .radix2,
                                      ofType: DSPSplitComplex.self) else {
                                        fatalError("Can't create FFT Setup.")
        }
        var inverseInputReal = signal_real
        var inverseInputImag = signal_imag
        var inverseOutputReal = [Float](repeating: 0, count: halfN)
        var inverseOutputImag = [Float](repeating: 0, count: halfN)

        inverseInputReal.withUnsafeMutableBufferPointer { forwardOutputRealPtr in
            inverseInputImag.withUnsafeMutableBufferPointer { forwardOutputImagPtr in
                inverseOutputReal.withUnsafeMutableBufferPointer { inverseOutputRealPtr in
                    inverseOutputImag.withUnsafeMutableBufferPointer { inverseOutputImagPtr in
                        
                        // 1: Create a `DSPSplitComplex` that contains the frequency domain data.
                        let forwardOutput = DSPSplitComplex(realp: forwardOutputRealPtr.baseAddress!,
                                                            imagp: forwardOutputImagPtr.baseAddress!)
                        
                        // 2: Create a `DSPSplitComplex` structure to receive the FFT result.
                        var inverseOutput = DSPSplitComplex(realp: inverseOutputRealPtr.baseAddress!,
                                                            imagp: inverseOutputImagPtr.baseAddress!)
                        
                        // 3: Perform the inverse FFT.
                        fftSetUp.inverse(input: forwardOutput,
                                         output: &inverseOutput)
                    }
                }
            }
        }
        
        return (inverseOutputReal, inverseOutputImag)
    }else{
        return ([0.0], [0.0])
    }
}
