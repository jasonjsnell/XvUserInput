//
//  Circle.swift
//  Refraktions
//
//  Created by Jason Snell on 11/27/16.
//  Copyright © 2016 Jason J. Snell. All rights reserved.
//

import Foundation

class Circle {
    
    internal var centerPoint:CGPoint = CGPoint(x: 0, y: 0)
    internal var radius:CGFloat = 0
    
    convenience init(centerPoint:CGPoint, radius:CGFloat){
        self.init()
        self.centerPoint = centerPoint
        self.radius = radius
    }
}

