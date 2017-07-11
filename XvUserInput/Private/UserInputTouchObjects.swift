//
//  UserInputTouchObjects.swift
//  XvUserInput
//
//  Created by Jason Snell on 7/9/17.
//  Copyright © 2017 Jason J. Snell. All rights reserved.
//


import UIKit

class UserInputTouchObjects {
    
    fileprivate var touchObjects:[XvUserInputTouchObject] = []
    
    fileprivate let debug:Bool = true
    
    //singleton code
    static public let sharedInstance = UserInputTouchObjects()
    fileprivate init(){}
    
    
    internal func add(touches: Set<UITouch>, inView:UIView) -> XvUserInputTouchObject? {
        
        //loop through incoming touches
        
        for touch in touches {
            
            var alreadyRecorded:Bool = false
            
            //loop through existing objects and see if there is a match
            for touchObject in touchObjects {
                
                if (touch == touchObject.touch){
                    print("already recorded")
                    alreadyRecorded = true
                }
            }
            
            //if not already recorded, then create new object and save it
            if (!alreadyRecorded){
                
                let newTouchObject:XvUserInputTouchObject = XvUserInputTouchObject(
                    withTouch: touch,
                    inView:inView
                )
                
                touchObjects.append(newTouchObject)
                
                return newTouchObject
                
            }
            
        }
        
        return nil
        
    }
    
    internal func allObjectsOn(){
        
        if (debug) { print("INPUT: All notes on for", touchObjects.count, "objects") }
        
        for touchObject in touchObjects {
            
            touchObject.on()
        }
        
    }
    
    internal func turnOff(touches:Set<UITouch>){
        
        //loop through touchesEnded touches
        
        for touch in touches {
            
            //loop through existing objects and see if there is a match
            for touchObject in touchObjects {
                
                if (touch == touchObject.touch){
                    if (debug) { print("INPUT: Turn", touchObject, "off") }
                    touchObject.off()
                    
                }
            }
        }
    }
    
    
    
    internal func removeAll(){
        
        print("INPUT: Remove all", touchObjects.count, "touch objects")
        
        //loop through and remove all
        for touchObject in touchObjects {
            
            remove(touchObject: touchObject)
        }
        
    }
    
    internal func remove(touchObject:XvUserInputTouchObject){
        
        print("INPUT: remove", touchObject)
        
        //run local removal code
        touchObject.remove()
        
        //remove from array
        if let removalIndex:Int = touchObjects.index(of: touchObject) {
            
            touchObjects.remove(at: removalIndex)
        }
        
    }
    
}

