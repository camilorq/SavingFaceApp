//
//  PlotInfo.swift
//  SavingFaceToF
//
//  MIT License
//
//  Copyright (c) 2020 Camilo Rojas, Niels Poulsen, James Pruegsanusak, Zhi Wei Gan
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

import UIKit
import AudioKitUI

class PlotInfo {
    
    //MARK: Properties
    var name: String
    var bufferLength: Int
    var startIndex: Int? {
        didSet {
            plot.startIndex = startIndex ?? 0
        }
    }
    var plot: ArrayOutputPlot

    var nameLabelText: String {
        get {
            var text = "\(name), len: \(bufferLength)"
            if let startIndex = startIndex {
                text += ", start: \(startIndex)"
            }
            return text
        }
    }
    
    //MARK: Initialization
    
    init(name: String, bufferLength: Int, color: UIColor, gain: Float? = nil,
         shouldCenterYAxis: Bool = true, startIndex: Int? = nil) {
        self.name = name
        self.bufferLength = bufferLength
        self.startIndex = startIndex

        plot = ArrayOutputPlot(
            frame: CGRect.zero, bufferSize: bufferLength, normalize: (gain == nil), startIndex: startIndex ?? 0
        )
        plot.translatesAutoresizingMaskIntoConstraints = true
        plot.shouldFill = false
        plot.shouldMirror = false
        plot.color = color
        plot.backgroundColor = UIColor.clear
        plot.gain = gain ?? 1.0
        plot.shouldCenterYAxis = shouldCenterYAxis
    }

}
