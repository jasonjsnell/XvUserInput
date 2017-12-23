//
//  XvUserInputTouchObject.swift
//  XvUserInput
//
//  Created by Jason Snell on 7/9/17.
//  Copyright © 2017 Jason J. Snell. All rights reserved.
//

import UIKit
import CoreGraphics

public class XvUserInputTouchObject:NSObject {
    
    //touch began (init)
    fileprivate var _touch:UITouch?
    fileprivate var _touchBeganPoint:CGPoint = CGPoint()
    fileprivate var _touchBeganTime:Date = Date()
    fileprivate var _on:Bool = false
    
    //touch & hold
    fileprivate var _touchAndHoldTimer:Timer = Timer()
    fileprivate var _isTouchAndHoldOccurring:Bool = false
    
    fileprivate var _isSwitchOccurring:Bool = false
    
    fileprivate let debug:Bool = false
    
    //MARK: GETTERS / SETTERS
    
    fileprivate var _inputX:Int = -1 //position for pitch
    
    public var inputX:Int {
        get { return _inputX }
        set {
            self._inputX = newValue
            //if (debug) { print("INPUT OBJ: Input X set to", newValue) }
        }
    }
    
    fileprivate var _inputY:Int = -1 //position for track
    public var inputY:Int {
        get { return _inputY }
        set {
            self._inputY = newValue
            //if (debug) { print("INPUT OBJ: Input Y set to", newValue) }
        }
    }
    
    public var touchBeganPoint:CGPoint {
        return _touchBeganPoint
    }
    
    internal var touch:UITouch? {
        return _touch
    }
    
    
    
    //MARK: - TOUCH BEGAN / init
    
    init(withTouch:UITouch, inView:UIView){
        
        super.init()
        
        if (debug){ print("INPUT OBJ: Init", self) }
        _touch = withTouch
        _touchBeganPoint = (withTouch.location(in: inView))
        _touchBeganTime = Date()
        
    }
    
    
    
    //MARK: - TOUCH & HOLD
    
    public func startTouchAndHoldTimer(withInterval:Double){
        
        _touchAndHoldTimer.invalidate()
        _touchAndHoldTimer = Timer.scheduledTimer(
            timeInterval: withInterval,
            target: self,
            selector: #selector(self._touchAndHoldTimerFire),
            userInfo: nil,
            repeats: true) 
        
    }
    
    @objc internal func _touchAndHoldTimerFire(){
       
        //if a hold is occuring
        if (_isTouchAndHoldOccurring){

            //an track area is being held
            if (inputY != -1){
                
                //TODO: Future: reactivate when input has its own screen
                /*
                Utils.postNotification(
                    name: XvUserInputConstants.kUserInputTouchAndHoldOnTrack,
                    userInfo: ["touchObject": self]
                )
                
                //rapid fire on note on
                on()
                
                
                //follow up with midi note off so it's not one long midi note on
                _sendMidiNoteOff(afterDelay: _touchAndHoldTimer.timeInterval * 0.9)
                 */
 
            } else {
                
                
                Utils.postNotification(
                    name: XvUserInputConstants.kUserInputTouchAndHoldOnNonTrack,
                    userInfo: ["touchObject": self]
                )
                
                //stop timer so it only sends message once
                _touchAndHoldCancel()
            }
            
        } else {
            
            //else if a hold is not occurring yet, check if hold time is over minimum, and start hold
            if (Date().timeIntervalSince(_touchBeganTime) > XvUserInputConstants.TOUCH_AND_HOLD_MIN_DURATION){
                
                _isTouchAndHoldOccurring = true
            }
        }
    }
    
    fileprivate func _resetTouchAndHold(){
        
        //record curr interval
        let timeInterval:TimeInterval = _touchAndHoldTimer.timeInterval
        
        //cancel loop
        _touchAndHoldCancel()
        
        //start over time of touch's beginning
        _touchBeganTime = Date()
        
        //restart the timer with the previous interval
        startTouchAndHoldTimer(withInterval: timeInterval)
        
    }
    
    fileprivate func _touchAndHoldCancel(){
        
        _touchAndHoldTimer.invalidate()
        _isTouchAndHoldOccurring = false
    }
    
    
    //MARK: - ON
    internal func on(){
        
        if (!_on || _isTouchAndHoldOccurring){
            
            _on = true
            
            //note on is only for track touches
            if (inputY != -1 && inputX != -1){
                
                if (debug){ print("INPUT OBJ:", self, "is turning on") }
                
                //adds new xvnote to system, midi on, anim, etc...
                Utils.postNotification(
                    name: XvUserInputConstants.kUserInputTouchObjectOn,
                    userInfo: ["touchObject": self]
                )
            
            }
            
        } else {
            
            if (debug){ print("INPUT OBJ:", self, "is already on") }
        }
    }
    
    
    
    //MARK: - OFF
    
    //called by userInputTouchObjects turnOff touches

    internal func off(){
        
        if (debug){ print("INPUT OBJ: Off") }
        
        let touchLength:Double = Date().timeIntervalSince(_touchBeganTime)
        
        if (touchLength > XvUserInputConstants.MIN_TAP_LENGTH_FOR_MIDI_NOTE) {
            
            _off()
            
        } else {
            
            let timeLeftUntilMinimum:Double = XvUserInputConstants.MIN_TAP_LENGTH_FOR_MIDI_NOTE - touchLength
            
            let when:DispatchTime = DispatchTime.now() + timeLeftUntilMinimum
             
            DispatchQueue.global(qos: .background).asyncAfter(deadline: when) {
                
                self._off()
            }
            
        }
        
        
        
    }
    
    fileprivate func _off(){
        
        if (debug){ print("INPUT OBJ: Off exe") }
        _on = false
        
        //always stop touch and hold on touches ended
        _touchAndHoldCancel()
        
        
        //was an track area hit, or the center?
        if (_inputX != -1 && _inputY != -1){
            
            //post notication
            Utils.postNotification(
                name: XvUserInputConstants.kUserInputTouchObjectOff,
                userInfo: ["touchObject": self]
            )
            
            //if this isn't called from touch and hold...
            //if this isn't called frmo a switch
            if (!_isTouchAndHoldOccurring && !_isSwitchOccurring){
                
                if (debug) { print("INPUT OBJ: Note off has been sent, object life complete") }
                _lifeComplete()
            }
            
        }  else {
            
            if (debug) { print("INPUT OBJ: Non-track zone, object life complete") }
            _lifeComplete()
            
        }
    }
    
    //MARK: - SWITCH
    
    //used when user drags tap from one y / track zone to another
    public func switchTo(newTouchBeganPoint:CGPoint, newInputX:Int, newInputY:Int) {
        
        if (debug){ 
            print("")
            print("INPUT OBJ: Switch")
        }
        
        //switch is beginning
        _isSwitchOccurring = true
        
        
        //MARK: clean up old object
        
        //resets
        _resetTouchAndHold()
        _on = false
        
    
        //was an track area hit?
        if (_inputX != -1 && _inputY != -1){
            
            //post, which updates the XvNote length and releases visual anims
            Utils.postNotification(
                name: XvUserInputConstants.kUserInputTouchObjectOff,
                userInfo: ["touchObject": self]
            )
        
        } /*else {
            
            //non intrument end (in RPC, a play / pause func)
            Utils.postNotification(
                name: XvUserInputConstants.kUserInputTouchObjectOffForNonTrack,
                userInfo: ["touchObject": self]
            )
        }*/
        
        
        
        //MARK: create new object
        
        //update vars
        _touchBeganPoint = newTouchBeganPoint
        _inputX = newInputX
        _inputY = newInputY
        
        
        //turn object on with new vars
        on()
        
        //switch is complete
        _isSwitchOccurring = false
    }
    
    
    //MARK: - REMOVE
    fileprivate func _lifeComplete(){
        
        if (debug){ print("INPUT OBJ: Touch object: Life complete") }
        
        Utils.postNotification(
            name: XvUserInputConstants.kUserInputTouchObjectLifeComplete,
            userInfo: ["touchObject" : self])
        
        UserInputTouchObjects.sharedInstance.remove(touchObject: self)
        
    }
    
    
    internal func remove(){
        
        _touchAndHoldCancel()
        _touch = nil
        _inputX = -1
        _inputY = -1
        
        if (debug){ print("INPUT OBJ: Touch object", self, "removed") }
        
        
    }
    
}
