//
//  Plot.swift
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

class PlotTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var ezPlot: EZAudioPlot!
    
    var plotInfo: PlotInfo! {
        didSet {
            nameLabel.text = plotInfo.nameLabelText

            let plot = plotInfo.plot
            plot.frame = ezPlot.bounds

            for subview in ezPlot.subviews {
                subview.removeFromSuperview()
            }
            ezPlot.addSubview(plot)

            var constraints = [plot.leadingAnchor.constraint(equalTo: ezPlot.leadingAnchor)]
            constraints.append(plot.trailingAnchor.constraint(equalTo: ezPlot.trailingAnchor))
            constraints.append(plot.topAnchor.constraint(equalTo: ezPlot.topAnchor))
            constraints.append(plot.bottomAnchor.constraint(equalTo: ezPlot.bottomAnchor))
            constraints.forEach { $0.isActive = true }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
