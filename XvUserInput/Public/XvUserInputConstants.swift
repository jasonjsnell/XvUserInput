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
    static let TOUCH_ASSESSMENT_DELAY:Double = 0.05 // can go down to 0.03 if tempo controller gets moved to a modulation panel
    static let TOUCHES_TO_TRIGGER_DRAG:Int = 3
    static let MIN_TAP_LENGTH_FOR_MIDI_NOTE:Double = 0.05
    static let TOUCH_AND_HOLD_MIN_DURATION:Double = 1.2 //0.7
    static let CENTER_BUTTON_RADIUS:CGFloat = 50
    
    
    //MARK: Values
    public static let SWIPE_DIRECTION_AWAY_FROM_CENTER:String = "swipeDirectionAwayFromCenter"
    public static let SWIPE_DIRECTION_RIGHT:String = "swipeDirectionRight"
    
    
    
    
    //MARK: Notifications
    public static let kUserInputTouchBegan:String = "kUserInputTouchBegan"
    public static let kUserInputTouchAssessmentComplete:String = "kUserInputTouchAssessmentComplete"
    public static let kUserInputTouchMoved:String = "kUserInputTouchMoved"
    public static let kUserInputTouchEnded:String = "kUserInputTouchEnded"
    public static let kUserInputAllTouchesEnded:String = "kUserInputAllTouchesEnded"
    
    public static let kUserInputDragBegan:String = "kUserInputDragBegan"
    public static let kUserInputDragMoved:String = "kUserInputDragMoved"
    public static let kUserInputDragEnded:String = "kUserInputDragEnded"
    
    public static let kUserInputRotationBegan:String = "kUserInputRotationBegan"
    public static let kUserInputRotationMoved:String = "kUserInputRotationMoved"
    public static let kUserInputRotationEnded:String = "kUserInputRotationEnded"
    public static let kUserInputReverseRotationCompleted:String = "kUserInputReverseRotationCompleted"
    
    public static let kUserInputSwipeBegan:String = "kUserInputSwipeBegan"
    public static let kUserInputSwipeEnded:String = "kUserInputSwipeEnded"
    
    public static let kUserInputTouchAndHoldOnTrack:String = "kUserInputTouchAndHoldOnTrack"
    public static let kUserInputTouchAndHoldOnCenter:String = "kUserInputTouchAndHoldOnCenter"
    public static let kUserInputTouchAndHoldOnNonTrack:String = "kUserInputTouchAndHoldOnNonTrack"
    
    public static let kUserInputCenterButtonTouch:String = "kUserInputCenterButtonTouch"
    
    public static let kUserInputShake:String = "kUserInputShake"
    
    public static let kUserInputTouchObjectOn:String = "kUserInputTouchObjectOn"
    public static let kUserInputTouchObjectOff:String = "kUserInputTouchObjectOff"
    
    public static let kUserInputTouchObjectMidiNoteOff:String = "kUserInputTouchObjectMidiNoteOff"
    public static let kUserInputTouchObjectLifeComplete:String = "kUserInputTouchObjectLifeComplete"
    
}
