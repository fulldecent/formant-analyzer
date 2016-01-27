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
    override func drawRect(rect: CGRect) {
        //TODO can do better!
        for view in self.subviews {
            view.removeFromSuperview()
        }
        
        guard self.formants.count >= 3 else {
            return
        }
        
        //TODO: maybe do this first
        // Now, we add an image to current view to plot location of first two formants
        let backgroundRect = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)
        let backgroundImageView = UIImageView(frame: backgroundRect)
        backgroundImageView.image = UIImage(named: "vowelPlotBackground.png")
        self.addSubview(backgroundImageView)
        
        // Choose the two formants we want to plot
        // If FF[2] is too close to FF[1], use FF[3] for vertical axis.
        let plottingFmtX = self.formants[0]
        let plottingFmtY: Double
        if self.formants[1] > 1.6 * self.formants[0] {
            plottingFmtY = self.formants[1]
        } else {
            plottingFmtY = self.formants[2]
        }

        // Translate from formant in Hz to x/y position as a portion of plot image
        // Need to consider scale of plot image and make it line up
        let plottingX = 0.103 + (plottingFmtX - 0) / 1200 * (0.953 - 0.103)
        let logPart = log(plottingFmtY) / log(2.0) - log(500.0) / log(2.0)
        let plottingY = (1.00 - 0.134) - logPart * (0.414 - 0.134)
        // Now translate into coordinate system of this image view
        let markerRect: CGRect = CGRectMake(self.frame.size.width * CGFloat(plottingX) - 7.5, self.frame.size.height * CGFloat(plottingY) - 7.5, 15.0, 15.0)
        let markerImageView: UIImageView = UIImageView(frame: markerRect)
        markerImageView.backgroundColor = UIColor.blackColor()
        self.addSubview(markerImageView)
        //MAYBE: if the f1 <= 1.6 * f2, consider plotting a second mark where the f2 actually is rathen than using f3
    }
}