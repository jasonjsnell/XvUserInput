//
//  XvUserInput.swift
//  XvUserInput
//
//  Created by Jason Snell on 7/9/17.
//  Copyright © 2017 Jason J. Snell. All rights reserved.
//
/*
 Handles user input, creating a system of touch objects that track each individual touch
 A lot of the code is app specific and handled in the helper class bc it requires many calls to other sections in the app
 
 
 IN
 User touches on main interface
 User touches in settings panel
 
 OUT
 Sequencer
 MIDI
 Visual Output
 User Data
 Defaults Manager
 */

import Foundation
import CoreGraphics
import UIKit
import UIKit.UIGestureRecognizerSubclass

public class XvUserInput:UIGestureRecognizer {
    
    //MARK:- VARIABLES
    
    //touch data
    fileprivate var _touchBeganPoint:CGPoint?
    fileprivate var _currNumOfTouchesOnScreen:Int = 0
    fileprivate var _touchAssessmentDelayTimer:Timer = Timer()
    
    //swipe vars (can be changed by app to customize swipe direction and start / end thresholds)
    fileprivate var _isSwipeOccurring:Bool = false
    fileprivate var _swipeDirection:String = XvUserInputConstants.SWIPE_DIRECTION_ANY
    fileprivate var _swipeStartDistanceThreshold:CGFloat = 5
    fileprivate var _swipeEndDistanceThreshold:CGFloat = 50
    
    fileprivate let debug:Bool = true
    
    //singleton code
    public static let sharedInstance = XvUserInput()
    fileprivate init(){
        super.init(target:nil, action:nil)
    }
    
    /*
     
     Sequence
     
     1. touchesBegan
     Start a short timer to give the interface a split second to determine the touch
     - A. Is it a one finger swipe?
     - B. Is it a three finger drag?
     - C. Is it a tap?
     
     2. touchAssessmentComplete
     At this point the system knows the type of interaction
     - A. Wait and see
     - B. Show tempo controller
     - C. Send note on command into touch objects
     
     
     3. touchesMoved
     - A. Nothing
     - B. Adjust tempo controller
     - C. Cancel if movement is a swipe or drag
     
     
     4. touchesEnded
     - A. Clear that rows instrument
     - B. Release tempo controller
     - C. Send note off command into touch objects
     
     */
    
    
    //MARK: - TOUCHES BEGAN
    //this fires with each finger that touches the screen
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        
        if (debug) {
            print("")
            print("INPUT: touchesBegan")
        }
        
        //reset
        _isSwipeOccurring = false
        _touchBeganPoint = nil
        
        
        //always add to user input objects, and if it's a swipe or drag, remove them later
        if (self.view != nil){
            
            //capture first touch vars for swipe and drag
            let touch:UITouch = touches.first!
            _touchBeganPoint = touch.location(in: self.view)
            _currNumOfTouchesOnScreen = event.allTouches!.count
            
            //MARK: Objects
            if let touchObjects:[XvUserInputTouchObject] = UserInputTouchObjects.sharedInstance.add(
                touches: touches,
                inView: self.view!) {
                
                //loop through the newly created touch objects and post a notification for each
                for touchObject in touchObjects {
                    
                    //MARK: Touch data
                    let touchBeganPoint = touchObject.touch.location(in: self.view)
                    
                    Utils.postNotification(
                        name: XvUserInputConstants.kUserInputTouchBegan,
                        userInfo: [
                            "touchBeganPoint" : touchBeganPoint,
                            "touchObject" : touchObject
                        ]
                    )
                    
                }
                
                
                //MARK: Touch assessment timer
                
                //create a short delay before executing touch began code
                //this allows enough time for the system to determine the type of touch
                
                _touchAssessmentDelayTimer.invalidate()
                _touchAssessmentDelayTimer = Timer.scheduledTimer(
                    timeInterval: XvUserInputConstants.TOUCH_ASSESSMENT_DELAY,
                    target: self,
                    selector: #selector(self.touchAssessmentComplete),
                    userInfo: nil,
                    repeats: false)
                
            } else {
                
                print("INPUT: Error: Touch object was not created during touchesBegan")
            }
        
        } else {
            
            print("INPUT: View is nil during touchesBegan")
        }
        
    }
    
    
    //MARK: Assess swipe
    //called by touches moved before timer is complete
    fileprivate func _assessSwipe(withTouchPoint:CGPoint){
        
        //need touch point and only 1 touch point
        if (_touchBeganPoint != nil && _currNumOfTouchesOnScreen == 1){
            
            //if there is a big enough positive differents between begin touch and move touch, swipe is occuring
            let swipeDistance:CGFloat = Utils.getDistance(
                betweenPointA: withTouchPoint,
                andPointB: _touchBeganPoint!
            )
            
            //if (debug){ print("INPUT: Assessing Swipe, distance", swipeDistance) }
            
            if (swipeDistance > _swipeStartDistanceThreshold){
                
                if (debug) { print("INPUT: Swipe is occurring") }
                _isSwipeOccurring = true
                
                Utils.postNotification(
                    name: XvUserInputConstants.kUserInputSwipeBegan,
                    userInfo: ["touchBeganPoint": _touchBeganPoint!]
                )
            }
        }
    }
    
    
    //MARK: - TOUCH ASSESSMENT COMPLETE
    
    //called after timer is complete
    internal func touchAssessmentComplete() {
        
        
        if (debug) {
            print("")
            print("INPUT: Touch assessment complete")
        }
        
        //this determines whether the current touch event is a drag, swipe, or tap inputs
        
        //MARK: Swipe
        if (_isSwipeOccurring){
            
            if (debug) { print("INPUT: Swipe is occurring") }
            
            UserInputTouchObjects.sharedInstance.removeAll()
            return
        }
        
        //MARK: Drag
        
        if (_currNumOfTouchesOnScreen >= XvUserInputConstants.TOUCHES_TO_TRIGGER_DRAG){
            
            Utils.postNotification(
                name: XvUserInputConstants.kUserInputDragBegan,
                userInfo: ["touchBeganPoint": _touchBeganPoint!]
            )
            
            UserInputTouchObjects.sharedInstance.removeAll()
            return
            
        }
        
        Utils.postNotification(
            name: XvUserInputConstants.kUserInputTouchAssessmentComplete,
            userInfo: nil
        )
        
        //MARK: Single taps
        UserInputTouchObjects.sharedInstance.allObjectsOn()
        
    }
    
    
    //MARK: - TOUCHES MOVED
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        
        //MARK: Swipe
        //don't execute touch code if right swipe is occurring
        if (_isSwipeOccurring){
            return
        }
        
        //MARK: Touch assessment
        let touch:UITouch = (event.allTouches!.first)!
        let touchMovedPoint:CGPoint = touch.location(in: self.view)
        
        Utils.postNotification(
            name: XvUserInputConstants.kUserInputTouchMoved,
            userInfo: ["touchMovedPoint": touchMovedPoint]
        )
        
        //if touch assessment is still occurring...
        if (_touchAssessmentDelayTimer.isValid){
            
            //assess right swipe
            _assessSwipe(withTouchPoint: touchMovedPoint)
            
            //then block the remaining code
            return
        }
        
        
        //MARK: Drag
        
        if (_currNumOfTouchesOnScreen >= XvUserInputConstants.TOUCHES_TO_TRIGGER_DRAG){
            
            Utils.postNotification(
                name: XvUserInputConstants.kUserInputDragMoved,
                userInfo: ["touchesMovedPoint": touchMovedPoint]
            )
        }
    }
    

    //MARK: - TOUCHES ENDED
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        
        if (debug) {
            print("")
            print("INPUT: Touch ended")
        }
        
        let touch:UITouch = (event.allTouches!.first)!
        let touchEndedPoint:CGPoint = touch.location(in: self.view)
        
        //MARK: Drag
        //always hide tempo controller as soon as any touch stops
        //tempo controller can handle calls to this even if it's not open
        
        Utils.postNotification(
            name: XvUserInputConstants.kUserInputDragEnded,
            userInfo: ["touchEndedPoint": touchEndedPoint]
        )
        
        //MARK: Swipe
        if (_isSwipeOccurring){
            
            _swipeEnded(atTouchPoint: touchEndedPoint)
            return
        }
        
        //MARK: Fast tap assessment
        //check to see if it's a very fast tap
        if (_touchAssessmentDelayTimer.isValid){
            
            //..stop the delay
            _touchAssessmentDelayTimer.invalidate()
            
            //and fire the assessment code immediately
            touchAssessmentComplete()
            
            if (debug) { print("INPUT: Very fast tap")}
            
        }
        
        //MARK: Single tap / touch
        if (_currNumOfTouchesOnScreen < XvUserInputConstants.TOUCHES_TO_TRIGGER_DRAG) {
            
            UserInputTouchObjects.sharedInstance.turnOff(touches: touches)
        }
        
    }
    
    //MARK: Swipe: Ended
    fileprivate func _swipeEnded(atTouchPoint:CGPoint) {
        
        //error checking
        if (_touchBeganPoint == nil){
            return
        }
        
        //confirm swipe was wide enough
        let swipeDistance:CGFloat = Utils.getDistance(betweenPointA: atTouchPoint, andPointB: _touchBeganPoint!)
        
        if (swipeDistance > _swipeEndDistanceThreshold){
            
            if (debug) { print("INPUT: Swipe has occurred") }
            
            Utils.postNotification(
                name: XvUserInputConstants.kUserInputSwipeEnded,
                userInfo: [
                    "touchBeganPoint" : _touchBeganPoint!,
                    "touchEndedPoint" : atTouchPoint
                ]
            )
            
            //reset
            _isSwipeOccurring = false
        }
    }
    
    //MARK: - TOUCHES CANCELLED
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        
        let touch:UITouch = (event.allTouches!.first)!
        let touchCancelledPoint:CGPoint = touch.location(in: self.view)
        
        
        Utils.postNotification(
            name: XvUserInputConstants.kUserInputDragEnded,
            userInfo: ["touchCancelledPoint": touchCancelledPoint]
        )
        
        UserInputTouchObjects.sharedInstance.removeAll()
    }
    
    //MARK: - SHAKE
    
    public func motionEnded(motion: UIEventSubtype, with event: UIEvent) {
        
        if motion == .motionShake {
            
            Utils.postNotification(
                name: XvUserInputConstants.kUserInputShake,
                userInfo: nil
            )
        }
    }
}
