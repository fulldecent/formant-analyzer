//
//  FormantPlotView.swift
//  FormantPlotter
//
//  Created by William Entriken on 1/21/16.
//  Copyright © 2016 William Entriken. All rights reserved.
//

import Foundation
import UIKit

class FormantPlotView: UIView {
    var formants = [Double]()

    /// The main display routine
    override func draw(_ rect: CGRect) {
        for view in self.subviews {
            view.removeFromSuperview()
        }
        
        // Now, we add an image to current view to plot location of first two formants
        let backgroundRect = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
        let backgroundImageView = UIImageView(frame: backgroundRect)
        backgroundImageView.image = UIImage(named: "vowelPlotBackground.png")
        self.addSubview(backgroundImageView)
        
        guard self.formants.count >= 3 else {
            return
        }
        
        // Choose the two formants we want to plot
        let plottingFmtX = self.formants[0]
        let plottingFmtY = self.formants[1]
        
        // Translate from formant in Hz to x/y position as a portion of plot image
        // Need to consider scale of plot image and make it line up
        let plottingX = 0.103 + (plottingFmtX - 0) / 1200 * (0.953 - 0.103)
        let logPart = log(plottingFmtY) / log(2.0) - log(500.0) / log(2.0)
        let plottingY = (1.00 - 0.134) - logPart * (0.414 - 0.134)

        // Now translate into coordinate system of this image view
        let markerRect: CGRect = CGRect(x: self.frame.size.width * CGFloat(plottingX) - 7.5, y: self.frame.size.height * CGFloat(plottingY) - 7.5, width: 15.0, height: 15.0)
        let markerImageView: UIImageView = UIImageView(frame: markerRect)
        markerImageView.backgroundColor = UIColor.black
        self.addSubview(markerImageView)

        // If `f2` is too close to `f1`, use `f3` for vertical axis.
        if self.formants[1] < 1.6 * self.formants[0] {
            let plottingFmtY = self.formants[2]
            let logPart = log(plottingFmtY) / log(2.0) - log(500.0) / log(2.0)
            let plottingY = (1.00 - 0.134) - logPart * (0.414 - 0.134)
            let markerRect: CGRect = CGRect(x: self.frame.size.width * CGFloat(plottingX) - 7.5, y: self.frame.size.height * CGFloat(plottingY) - 7.5, width: 15.0, height: 15.0)
            let markerImageView: UIImageView = UIImageView(frame: markerRect)
            markerImageView.backgroundColor = UIColor.gray
            self.addSubview(markerImageView)
        }
    }
}
