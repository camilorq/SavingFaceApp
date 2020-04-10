//
//  Plot.swift
//  SavingFaceToF
//
//  Created by Korrawat Pruegsanusak on 4/2/20.
//  Copyright © 2020 mit_ml_niels. All rights reserved.
//

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
