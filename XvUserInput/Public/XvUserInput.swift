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
    
    //TODO: For multi view, I need to be able to pass in views to have certain listeners
    
    //touch data
    fileprivate var _touchBeganPoint:CGPoint?
    fileprivate var _currNumOfTouchesOnScreen:Int = 0
    fileprivate var _touchAssessmentDelayTimer:Timer = Timer()
    
    //swipe vars (can be changed by app to customize swipe direction and start / end thresholds)
    fileprivate var _isSwipeOccurring:Bool = false
    fileprivate var _swipeDirection:String = ""
    fileprivate var _swipeStartDistanceThreshold:CGFloat = 5
    fileprivate var _swipeEndDistanceThreshold:CGFloat = 50
    
    //rotation
    fileprivate var _isRotationOccurring:Bool = false
    
    //center tap
    fileprivate var _isCenterTouchOccurring:Bool = false
    fileprivate var _isCenterTouchAndHoldOccurring:Bool = false
    
    fileprivate let debug:Bool = true
    
    //singleton code
    public static let sharedInstance = XvUserInput()
    fileprivate init(){
        super.init(target:nil, action:nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(_assessTouchAndHoldOnNonInstrument),
            name: Notification.Name(rawValue: XvUserInputConstants.kUserInputTouchAndHoldOnNonInstrument),
            object: nil
        )
    }
    
    
    //MARK: - ACCESSORS
    
    public func getTouchObjects() -> [XvUserInputTouchObject]? {
        return UserInputTouchObjects.sharedInstance.getTouchObjects()
    }
    
    public func getTouchObject(fromTouch:UITouch) -> XvUserInputTouchObject? {
        return UserInputTouchObjects.sharedInstance.getTouchObject(fromTouch: fromTouch)
    }
    
    public var swipeDirection:String {
        get { return _swipeDirection }
        set { self._swipeDirection = newValue }
    }
    
   
    
    /*
     
     Sequence
     
     1. touchesBegan
     Start a short timer to give the interface a split second to determine the touch
     - A. Is it a one finger swipe?
     - B. Is it a multi-finger drag?
     - C. Is it an instrument tap?
     - D. Is it a center tap?
     
     2. touchAssessmentComplete
     At this point the system knows the type of interaction
     - A. If swipe, block other code
     - B. Show tempo controller
     - C. Send note on command into touch objects
     - D. Nothing
     
     
     3. touchesMoved
     - A. Assess for swipe until assessment is complete
     - B. Adjust tempo controller
     - C. Cancel if movement is a swipe or drag
     - D. If moved off center, cancel input
     
     
     4. touchesEnded
     - A. Clear that rows instrument
     - B. Release tempo controller
     - C. Send note off command into touch objects
     - D. Play / pause system
     
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
        _isCenterTouchOccurring = false
        _isCenterTouchAndHoldOccurring = false
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

    
    //MARK: - TOUCH ASSESSMENT COMPLETE
    
    //called after timer is complete
    @objc internal func touchAssessmentComplete() {
        
        if (debug) {
            print("")
            print("INPUT: Touch assessment complete")
        }
        
        Utils.postNotification(
            name: XvUserInputConstants.kUserInputTouchAssessmentComplete,
            userInfo: nil
        )
        
        //this determines whether the current touch event is a drag, swipe, or tap inputs
        
        //MARK: Center tap
       
        if (_currNumOfTouchesOnScreen == 1){
            
            //test to see if touch is in center
            _isCenterTouchOccurring = _isInCenter(touchPoint: _touchBeganPoint!)
            
            if (_isCenterTouchOccurring) {
                return
            }
        }
        
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
                userInfo: ["dragBeganPoint": _touchBeganPoint!]
            )
            
            UserInputTouchObjects.sharedInstance.removeAll()
            return
            
        }
        
        //MARK: Single taps
        UserInputTouchObjects.sharedInstance.allObjectsOn()
        
    }
    
    
    //MARK: - SWIPE ASSESSMENT
    //called by touches moved before timer is complete
    fileprivate func _assessSwipe(withTouchPoint:CGPoint){
        
        //need touch point and only 1 touch point
        if (_touchBeganPoint != nil && _currNumOfTouchesOnScreen == 1){
            
            //swipe away from the center RPC
            if (_swipeDirection == XvUserInputConstants.SWIPE_DIRECTION_AWAY_FROM_CENTER){
                
                if (self.view != nil){
                    
                    //get distance from center
                    let swipeDistance:CGFloat = _getSwipeDistanceFromCenter(
                        startPoint: _touchBeganPoint!,
                        endPoint: withTouchPoint
                    )
                    
                    //if (debug){ print("INPUT: Assessing Swipe, distance", swipeDistance) }
                    
                    if (swipeDistance > _swipeStartDistanceThreshold){
                        
                        if (debug) { print("INPUT: Swipe is occurring") }
                        _isSwipeOccurring = true
                    }
                    
                } else {
                    print("INPUT: Error getting view during swipe assessment")
                }
                
                
            } else if (_swipeDirection == XvUserInputConstants.SWIPE_DIRECTION_RIGHT) {
                
                //swipe right RF
                
            }
            
            //if true, post notification
            if (_isSwipeOccurring){
                
                Utils.postNotification(
                    name: XvUserInputConstants.kUserInputSwipeBegan,
                    userInfo: ["touchBeganPoint": _touchBeganPoint!]
                )
            }
        }
    }
    
    //MARK: - ASSESS TOUCH & HOLD
    
    @objc public func _assessTouchAndHoldOnNonInstrument(notification:Notification) -> Void {
        
        //assess touch and hold notification from non instrument
        if (_isCenterTouchOccurring) {
            
            _isCenterTouchAndHoldOccurring = true
            
            //if it's a center touch and hold, post new notification
            Utils.postNotification(
                name: XvUserInputConstants.kUserInputTouchAndHoldOnCenter,
                userInfo: nil
            )
            
        }
        
    }
    
    //MARK: - TOUCHES MOVED
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        
        let firstTouch:UITouch = (event.allTouches!.first)!
        let firstTouchMovedPoint:CGPoint = firstTouch.location(in: self.view)
        
        //MARK: Center tap
        
        //if tap started in center...
        if (_isCenterTouchOccurring){
            
            //is it still in center?
            let isStillInCenter:Bool = _isInCenter(touchPoint: firstTouchMovedPoint)
            
            //if not
            if (!isStillInCenter){
                
                //drop all objects
                UserInputTouchObjects.sharedInstance.removeAll()
                return
            }
            
            return
        }
        
        //MARK: Swipe
        //don't execute touch moved code if swipe is occurring
        if (_isSwipeOccurring){
            return
        }
        
        
        //if touch assessment is still occurring...
        if (_touchAssessmentDelayTimer.isValid){
            
            //assess right swipe
            _assessSwipe(withTouchPoint: firstTouchMovedPoint)
            
            //then block the remaining code
            return
        }
        
        
        //MARK: Drag
        
        //if above drag threshold
        if (_currNumOfTouchesOnScreen >= XvUserInputConstants.TOUCHES_TO_TRIGGER_DRAG){
            
            //notify as drag, using first touch as the anchor
            Utils.postNotification(
                name: XvUserInputConstants.kUserInputDragMoved,
                userInfo: ["dragMovedPoint": firstTouchMovedPoint]
            )
            
            //then block the remaining code
            return
        }
        
        //MARK: Tap movements
        
        //loop through all the touches and post notifications for each
        for touch in touches {
            
            if let touchObject:XvUserInputTouchObject = UserInputTouchObjects.sharedInstance.getTouchObject(fromTouch: touch) {
                
                //use current location, not the touch began point
                let touchMovedPoint = touch.location(in: self.view)
                
                Utils.postNotification(
                    name: XvUserInputConstants.kUserInputTouchMoved,
                    userInfo: [
                        "touchMovedPoint" : touchMovedPoint,
                        "touchObject" : touchObject
                    ]
                )
                
            }
        }
        
    }
    

    //MARK: - TOUCHES ENDED
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        
        if (debug) {
            print("")
            print("INPUT: Touch ended")
        }
        
        let firstTouch:UITouch = (event.allTouches!.first)!
        let firstTouchEndedPoint:CGPoint = firstTouch.location(in: self.view)
        
        //MARK: Drag
        //always hide tempo controller as soon as any touch stops
        //tempo controller can handle calls to this even if it's not open
        
        Utils.postNotification(
            name: XvUserInputConstants.kUserInputDragEnded,
            userInfo: ["dragEndedPoint": firstTouchEndedPoint]
        )
        
        //MARK: Fast gesture assessment
        //check to see if it's a very fast gesture
        if (_touchAssessmentDelayTimer.isValid){
            
            //..stop the delay
            _touchAssessmentDelayTimer.invalidate()
            
            //and fire the assessment code immediately
            touchAssessmentComplete()
            
            if (debug) { print("INPUT: Very fast gesture")}
            
        }
        
        //MARK: Swipe
        if (_isSwipeOccurring){
            
            _swipeEnded(atTouchPoint: firstTouchEndedPoint)
            return
        }
        
        
        //MARK: Center tap
        if (_isCenterTouchOccurring){
            
            //is it still in center?
            let isStillInCenter:Bool = _isInCenter(touchPoint: firstTouchEndedPoint)
            
            //if still in center and it's not a touch and hold
            if (isStillInCenter && !_isCenterTouchAndHoldOccurring){
                
                //post notification for center button touch
                Utils.postNotification(
                    name: XvUserInputConstants.kUserInputCenterButtonTouch,
                    userInfo: nil
                )
                
                //cleanup
                UserInputTouchObjects.sharedInstance.removeAll()
            }
            
            return
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
        //get distance from center
        let swipeDistance:CGFloat = _getSwipeDistanceFromCenter(
            startPoint: _touchBeganPoint!,
            endPoint: atTouchPoint
        )
        
        if (swipeDistance > _swipeEndDistanceThreshold){
            
            if (debug) { print("INPUT: Swipe has occurred") }
            
            Utils.postNotification(
                name: XvUserInputConstants.kUserInputSwipeEnded,
                userInfo: [
                    "swipeBeganPoint" : _touchBeganPoint!,
                    "swipeEndedPoint" : atTouchPoint
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
    
    //MARK: - ROTATION
    

    @objc public func circleDetected(recognizer:XvCircleGestureRecognizer){
        
        //don't execute code if there are more than 2 touches
        //because that means it's a tempo controller change
        if (_currNumOfTouchesOnScreen > 1){
            return
        }
        
        if (recognizer.state == .changed){
            
            //MARK:ROTATION TEST
            
            // if...
            // touch count is 1
            // touch began in circle zone C
            // touch is currently in circle zone C
            // and rotation amount is significant
            // and gesture angle is not zero (meaning it's beyong the init value)
            
            if (_currNumOfTouchesOnScreen == 1 &&
                recognizer.didTouchBeginInOuterCircleCZone() &&
                recognizer.isTouchInOuterCircleCZone() &&
                recognizer.isRotationSignificant() &&
                recognizer.gestureAngle != 0){
                
                //MARK:ROTATION START
                //is this the beginning of a circle? (is _isRotationOccurring still false?)
                if (!_isRotationOccurring){
                    
                    
                    Utils.postNotification(
                        name: XvUserInputConstants.kUserInputRotationBegan,
                        userInfo: nil
                    )
                    
                    //drag is now occurring
                    _isRotationOccurring = true
                    
                    if (debug) { print("INPUT: Rotation is occurring") }
                    
                }
                
                //MARK:ROTATE JOG WHEEL
                
                Utils.postNotification(
                    name: XvUserInputConstants.kUserInputRotationMoved,
                    userInfo: ["gestureAngle" : recognizer.gestureAngle]
                )
    
            }
            
            //MARK:ROTATION LEAVING BOUNDS
            // if drag is occuring
            // and touch is no longer in circle zone
            
            if (_isRotationOccurring && !recognizer.isTouchInOuterCircleCZone()){
                
                Utils.postNotification(
                    name: XvUserInputConstants.kUserInputRotationEnded,
                    userInfo: nil
                )
                
            }
            
        } else if (recognizer.state == .ended){
            
            //MARK:ROTATION END
            
            //TODO: post notification that rotation has ended
            //always end scrub when state is ended (prevents sequencer from getting stuck in pause state
            //XvSeqSystem.sharedInstance.scrubEnded()
            
            // only execute circle ended code if circle moved code had been running
            // (used to prevent this from firing on taps / swipes)
            
            if (_isRotationOccurring){
                
                //rotation is over
                _isRotationOccurring = false
                //VisualOutput.sharedInstance.rotationEnded()
                
                
                //MARK:ROTATION RESET
                
                //if gesture is counter clockwise circle...
                if (recognizer.rotationDirection == .rotationCounterClockwise){
                    
                    //...do a sequencer reset
                    
                    //TODO: post notification for seq reset
                    //clear out all the note data
                    //XvSeqSystem.sharedInstance.removeAllNotes()
                    //XvSeqSystem.sharedInstance.resetUserData()
                    //XvMidi.sharedInstance.allNotesOff()
                    //VisualOutput.sharedInstance.midiIndicatorOff()
                    //VisualOutput.sharedInstance.resetAllInstrumentMonitors()
                    //VisualOutput.sharedInstance.animChannelUsage(percentageOfBusyChannels: 0)
                    
                    //if sync is not external...
                    /*if (dm.getString(forKey: XvMidiConstants.kMidiSync) != XvMidiConstants.MIDI_CLOCK_RECEIVE &&
                        !dm.getBool(forKey: XvAbletonLinkConstants.kXvAbletonLinkEnabled)){
                        
                        //restart sequencers to position 0, 0
                        XvSeqSystem.sharedInstance.restart()
                        XvMidi.sharedInstance.sequencerRestart()
                        
                    }*/
                    
                    //output text message
                    //VisualOutput.sharedInstance.pulseText(header: "Reset", sub: "Sequencer restart")
                    
                    /*if (debug){
                        print("INPUT: Remove all notes from song")
                    }*/
                    
                }
                
            }
            
        } else {
            _isRotationOccurring = false
            
            //TODO: post notif
            //XvSeqSystem.sharedInstance.scrubEnded()
        }
        
    }

    
    //MARK: - HELPERS
    fileprivate func _isInCenter(touchPoint:CGPoint) -> Bool {
        
        var _centerBool:Bool = false
        
        //get center point
        let centerPoint:CGPoint = CGPoint(
            x: (self.view!.frame.width) / 2,
            y: (self.view!.frame.height) / 2
        )
        
        //get distance from center
        let distanceFromCenter:CGFloat = Utils.getDistance(
            betweenPointA: centerPoint,
            andPointB: touchPoint
        )
        
        if (distanceFromCenter < XvUserInputConstants.CENTER_BUTTON_RADIUS){
            
            _centerBool = true
        }
        
        return _centerBool
    }
    
    fileprivate func _getSwipeDistanceFromCenter(startPoint:CGPoint, endPoint:CGPoint) -> CGFloat {
        
        let centerPoint:CGPoint = CGPoint(
            x: (self.view!.frame.width) / 2,
            y: (self.view!.frame.height) / 2
        )
        
        let startPointDistanceFromCenter:CGFloat = Utils.getDistance(
            betweenPointA: centerPoint,
            andPointB: startPoint
        )
        
        let endPointPointDistanceFromCenter:CGFloat = Utils.getDistance(
            betweenPointA: centerPoint,
            andPointB: endPoint)
        
        return endPointPointDistanceFromCenter - startPointDistanceFromCenter
    }
}
