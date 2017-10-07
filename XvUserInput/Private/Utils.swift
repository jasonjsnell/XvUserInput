//
//  Utils.swift
//  XvUserInput
//
//  Created by Jason Snell on 7/9/17.
//  Copyright © 2017 Jason J. Snell. All rights reserved.
//

import Foundation

class Utils {
    
    //MARK: - NOTIFICATIONS -
    class func postNotification(name:String, userInfo:[AnyHashable : Any]?){
        
        let notification:Notification.Name = Notification.Name(rawValue: name)
        NotificationCenter.default.post(
            name: notification,
            object: nil,
            userInfo: userInfo)
    }
    
    
    
    //MARK: GEOMETRY
    public class func getDistance(betweenPointA:CGPoint, andPointB:CGPoint) -> CGFloat {
        let xDist = betweenPointA.x - andPointB.x
        let yDist = betweenPointA.y - andPointB.y
        return CGFloat(sqrt((xDist * xDist) + (yDist * yDist)))
    }
    
    
    //MARK: CIRCLES
    
    //CONVERSIONS
    class func getRadian(ofView:UIView) -> Float {
        return (atan2f(Float(ofView.transform.b), Float(ofView.transform.a)))
    }
    
    class func getDegree(ofView:UIView) -> Double {
        let radian:Float = getRadian(ofView: ofView)
        return getDegree(fromRadian: Double(radian))
    }
    
    class func getRadian(fromDegree:Double) -> Double {
        return fromDegree * Double.pi / 180
    }
    
    class func getDegree(fromRadian:Double) -> Double {
        return fromRadian * 180 / Double.pi
    }
    
    
    //HIT TESTS
    
    class func testIs(point:CGPoint, inCircle:Circle) -> Bool {
        
        //extract vars
        let radius:CGFloat = inCircle.radius
        let centerX:CGFloat = inCircle.centerPoint.x
        let centerY:CGFloat = inCircle.centerPoint.y
        
        //test to see if x and y points are in radius
        let isXInRadius:Bool = point.x >= centerX - radius && point.x <= centerX + radius
        let isYInRadius:Bool = point.y >= centerY - radius && point.y <= centerY + radius
        
        //circle distance calculations
        if (isXInRadius && isYInRadius) {
            var dx:CGFloat = inCircle.centerPoint.x - point.x
            var dy:CGFloat = inCircle.centerPoint.y - point.y
            dx *= dx
            dy *= dy
            let distanceSquared:CGFloat = dx + dy
            let radiusSquared:CGFloat = inCircle.radius * inCircle.radius
            
            let isDistanceLessThanRadius:Bool = distanceSquared <= radiusSquared
            return isDistanceLessThanRadius
        }
        
        //else false
        return false
        
    }
    
    class func testIs(point:CGPoint,
                      betweenSmallCircle:Circle,
                      andLargeCircle:Circle) -> Bool {
        
        let isPointInsideLargeCircle:Bool = testIs(point: point, inCircle: andLargeCircle)
        
        //only true if the point is inside the large...
        if (isPointInsideLargeCircle){
            
            let isPointInsideSmallCircle:Bool = testIs(point: point, inCircle: betweenSmallCircle)
            
            //... but not inside the small circle
            if (!isPointInsideSmallCircle){
                return true
            }
        }
        
        //else false
        return false
    }
    
}


