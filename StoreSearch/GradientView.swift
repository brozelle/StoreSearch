//
//  GradientView.swift
//  StoreSearch
//
//  Created by Buck Rozelle on 5/4/20.
//  Copyright © 2020 buckrozelledotcomLLC. All rights reserved.
//

import UIKit
class GradientView: UIView {
    
    //set the background color to clear
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
    }
    
    //set the background to fully transparent
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = UIColor.clear
    }
    override func draw(_ rect: CGRect) {
        //create arrays for the color stops of the gradient
        let components: [CGFloat] = [ 0, 0, 0, 0.3, 0, 0, 0, 0.7 ]
        let locations: [CGFloat] = [ 0, 1 ]
        
        //create the gradient object
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradient(colorSpace: colorSpace,
                                  colorComponents: components,
                                  locations: locations, count: 2)
        //draw the gradient object
        let x = bounds.midX
        let y = bounds.midY
        let centerPoint = CGPoint(x: x, y : y)
        let radius = max(x, y)
        
        //draw the object
        let context = UIGraphicsGetCurrentContext()
        context?.drawRadialGradient(gradient!,
                                    startCenter: centerPoint, startRadius: 0,
                                    endCenter: centerPoint, endRadius: radius,
                                    options: .drawsAfterEndLocation)
    }
}
