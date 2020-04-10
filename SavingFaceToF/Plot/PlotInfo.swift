//
//  PlotInfo.swift
//  SavingFaceToF
//
//  Created by Korrawat Pruegsanusak on 4/2/20.
//  Copyright © 2020 mit_ml_niels. All rights reserved.
//

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
