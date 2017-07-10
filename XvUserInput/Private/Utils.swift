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
    
}


