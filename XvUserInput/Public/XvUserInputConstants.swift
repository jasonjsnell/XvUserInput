//
//  XvUserInputConstants.swift
//  XvUserInput
//
//  Created by Jason Snell on 7/9/17.
//  Copyright © 2017 Jason J. Snell. All rights reserved.
//

import Foundation

public class XvUserInputConstants {
    
    //MARK: Constants
    static let TOUCH_ASSESSMENT_DELAY:Double = 0.05 //0.08
    static let TOUCHES_TO_TRIGGER_DRAG:Int = 4
    static let MIN_TAP_LENGTH_FOR_MIDI_NOTE:Double = 0.05
    static let DEFAULT_NOTE_LENGTH:Double = 0.1
    static let TOUCH_AND_HOLD_MIN_DURATION:Double = 2.0 //0.7
    static let CENTER_BUTTON_RADIUS:CGFloat = 60
    
    
    //MARK: Values
    public static let SWIPE_DIRECTION_AWAY_FROM_CENTER:String = "swipeDirectionAwayFromCenter"
    public static let SWIPE_DIRECTION_RIGHT:String = "swipeDirectionRight"
    
    
    
    
    //MARK: Notifications
    public static let kUserInputTouchBegan:String = "kUserInputTouchBegan"
    public static let kUserInputTouchAssessmentComplete:String = "kUserInputTouchAssessmentComplete"
    public static let kUserInputTouchMoved:String = "kUserInputTouchMoved"
    public static let kUserInputTouchEnded:String = "kUserInputTouchEnded"
    
    public static let kUserInputDragBegan:String = "kUserInputDragBegan"
    public static let kUserInputDragMoved:String = "kUserInputDragMoved"
    public static let kUserInputDragEnded:String = "kUserInputDragEnded"
    
    public static let kUserInputSwipeBegan:String = "kUserInputSwipeBegan"
    public static let kUserInputSwipeEnded:String = "kUserInputSwipeEnded"
    
    public static let kUserInputTouchObjectTouchAndHoldOnInstrument:String = "kUserInputTouchObjectTouchAndHoldOnInstrument"
    public static let kUserInputTouchObjectTouchAndHoldOnNonInstrument:String = "kUserInputTouchObjectTouchAndHoldOnNonInstrument"
    
    public static let kUserInputCenterButtonTouch:String = "kUserInputCenterButtonTouch"
    
    
    
    
    public static let kUserInputShake:String = "kUserInputShake"
    
    public static let kUserInputTouchObjectOn:String = "kUserInputTouchObjectOn"
    public static let kUserInputTouchObjectOffForInstrument:String = "kUserInputTouchObjectOffForInstrument"
    public static let kUserInputTouchObjectOffForCenter:String = "kUserInputTouchObjectOffForCenter"
    public static let kUserInputTouchObjectMidiNoteOff:String = "kUserInputTouchObjectMidiNoteOff"
    public static let kUserInputTouchObjectLifeComplete:String = "kUserInputTouchObjectLifeComplete"
    
}
