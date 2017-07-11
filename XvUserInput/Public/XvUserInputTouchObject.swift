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
    
    fileprivate var _inputX:Int = -1 //position for pitch
    fileprivate var _inputY:Int = -1 //position for instrument
    
    
    //touch began (init)
    fileprivate var _touch:UITouch?
    fileprivate var _touchBeganPoint:CGPoint = CGPoint()
    fileprivate var _touchBeganTime:Date = Date()
    fileprivate var _on:Bool = false
    
    //touch & hold
    fileprivate var _touchAndHoldTimer:Timer = Timer()
    fileprivate var _isTouchAndHoldOccurring:Bool = false
    
    
    //note on
    fileprivate var _musicalNote:Int = 60
    
    //note off
    fileprivate var _touchLength:TimeInterval = TimeInterval()
    fileprivate var _sendMidiOffTimer:Timer = Timer()
    
    fileprivate let debug:Bool = true
    
    //MARK: GETTERS / SETTERS
    
    public var inputX:Int {
        get { return _inputX }
        set {
            self._inputX = newValue
            //if (debug) { print("INPUT OBJ: Input X set to", newValue) }
        }
    }
    
    public var inputY:Int {
        get { return _inputY }
        set {
            self._inputY = newValue
            //if (debug) { print("INPUT OBJ: Input Y set to", newValue) }
        }
    }
    
    public var musicalNote:Int {
        get { return _musicalNote }
        set { self._musicalNote = newValue }
    }
    
    public var touchBeganPoint:CGPoint {
        return _touchBeganPoint
    }
    
    public var touchLength:Double {
        return _touchLength
    }
    
    internal var touch:UITouch {
        return _touch!
    }
    
    
    
    //MARK: - TOUCH BEGAN / init
    
    
    init(withTouch:UITouch, inView:UIView){
        
        super.init()
        
        print("INPUT OBJ: Init", self)
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
    
    internal func _touchAndHoldTimerFire(){
        
        //if a hold is occuring
        if (_isTouchAndHoldOccurring){

            //an instrument area is being held
            if (inputY != -1){
                
                Utils.postNotification(
                    name: XvUserInputConstants.kUserInputTouchObjectTouchAndHoldOnInstrument,
                    userInfo: ["touchObject": self]
                )
                
                //rapid fire on note on
                on()
                
                
                //follow up with midi note off so it's not one long midi note on
                _sendMidiNoteOff(afterDelay: _touchAndHoldTimer.timeInterval * 0.9)
                
            } else {
                
                //a non instrument area is being held
                
                Utils.postNotification(
                    name: XvUserInputConstants.kUserInputTouchObjectTouchAndHoldOnNonInstrument,
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
    
    fileprivate func _touchAndHoldCancel(){
        
        _touchAndHoldTimer.invalidate()
        _isTouchAndHoldOccurring = false
    }
    
    
    //MARK: - ON
    internal func on(){
        
        if (!_on || _isTouchAndHoldOccurring){
            
            _on = true
            
            //note on is only for instrument touches
            if (inputY != -1 && inputX != -1){
                
                if (debug){ print("INPUT OBJ:", self, "is turning on") }
                
                Utils.postNotification(
                    name: XvUserInputConstants.kUserInputTouchObjectOn,
                    userInfo: ["touchObject": self]
                )
            }
            
        } else {
            
            if (debug){ print("INPUT OBJ:", self, "is already on") }
        }
    }
    
    
    
    //MARK: - NOTE OFF
    internal func off(){
        
        //if (debug){ print("INPUT OBJ: Off") }
        
        _on = false
    
        //always stop touch and hold on touches ended
        _touchAndHoldCancel()
        
        
        //was an instrument area hit, or the center?
        if (_inputX != -1 && _inputY != -1){
            
            //MARK: Touch length
            //calc how long it's been since the touch began
            _touchLength = Date().timeIntervalSince(_touchBeganTime)
                
            //push length to at least minimum so each MIDI note can trigger
            var touchLengthDeficit:Double = XvUserInputConstants.MIN_TAP_LENGTH_FOR_MIDI_NOTE
                
            if (_touchLength < XvUserInputConstants.MIN_TAP_LENGTH_FOR_MIDI_NOTE){
                touchLengthDeficit = XvUserInputConstants.MIN_TAP_LENGTH_FOR_MIDI_NOTE - _touchLength
                _touchLength = XvUserInputConstants.MIN_TAP_LENGTH_FOR_MIDI_NOTE
            }
            
            Utils.postNotification(
                name: XvUserInputConstants.kUserInputTouchObjectOffForInstrument,
                userInfo: ["touchObject": self]
            )
            
            //MARK: MIDI note off
            _sendMidiNoteOff(afterDelay: touchLengthDeficit)
            
            
        } else {
            
            //non intrument end
            Utils.postNotification(
                name: XvUserInputConstants.kUserInputTouchObjectOffForNonInstrument,
                userInfo: ["touchObject": self]
            )
            
            print("INPUT OBJ: Center tap release, object life complete")
            _lifeComplete()
            
        }
    }
    
    
    fileprivate func _sendMidiNoteOff(afterDelay:Double) {
        
        //set up timer for note off command
        _sendMidiOffTimer.invalidate()
        _sendMidiOffTimer = Timer.scheduledTimer(
            timeInterval: afterDelay,
            target: self,
            selector: #selector(self._midiNoteOff),
            userInfo: nil,
            repeats: false)
        
    }
    
    
    internal func _midiNoteOff(){
        
        Utils.postNotification(
            name: XvUserInputConstants.kUserInputTouchObjectMidiNoteOff,
            userInfo: ["touchObject" : self])
        
        
        //if this isn't be called from touch and hold...
        if (!_isTouchAndHoldOccurring){
            
            //print("INPUT OBJ: MIDI note off has been sent, object life complete")
            _lifeComplete()
        }
    }
    
    
    //MARK: - REMOVE
    fileprivate func _lifeComplete(){
        
        //if (debug){ print("INPUT OBJ: Touch object: Life complete") }
        
        Utils.postNotification(
            name: XvUserInputConstants.kUserInputTouchObjectLifeComplete,
            userInfo: ["touchObject" : self])
        
        UserInputTouchObjects.sharedInstance.remove(touchObject: self)
        
    }
    
    
    internal func remove(){
        
        _touchAndHoldCancel()
        _sendMidiOffTimer.invalidate()
        _touch = nil
        _inputX = -1
        _inputY = -1
        
        //if (debug){ print("INPUT OBJ: Touch object", self, "removed") }
        
        
    }
    
    
    
}
