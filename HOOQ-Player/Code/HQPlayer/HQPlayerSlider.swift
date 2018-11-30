 //
//  HQSlider.swift
//  HOOQ-Player
//
//  Created by Rohan Chalana on 7/8/18.
//  Copyright © 2018 HOOQ. All rights reserved.
//

import Foundation
import UIKit
class HQPlayerSlider: UISlider {
    override open func trackRect(forBounds bounds: CGRect) -> CGRect {
            var newBounds = super.trackRect(forBounds: bounds)
            newBounds.size.height = 4
            newBounds.origin.y -= 2
            return newBounds
    }
 }
