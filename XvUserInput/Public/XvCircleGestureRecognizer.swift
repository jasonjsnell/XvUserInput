//
//  XvCircleGestureRecognizer.swift
//  XvUserInput
//
//  Created by Jason Snell on 10/6/17.
//  Copyright © 2017 Jason J. Snell. All rights reserved.
//


import Foundation
import UIKit
import UIKit.UIGestureRecognizerSubclass

public class XvCircleGestureRecognizer: UIGestureRecognizer {
    
    //MARK: - VARS -
    
    //rotation direction
    internal enum Rotation:Int  {
        case rotationUnknown = 0
        case rotationClockwise = 1
        case rotationCounterClockwise = 2
    }
    
    //MARK: - PUBLIC
    internal var rotationDirection:Rotation = .rotationUnknown
    internal var gestureAngle: Double = 0
    
    //MARK: - PRIVATE
    fileprivate var rotationCounter:Int = 0
    fileprivate let SIGNICANT_ROTATION_RANGE:Int = 1
    
    //bools
    fileprivate var touchBeganInOuterCircleCZone:Bool = false
    fileprivate var touchInOuterCircleCZone:Bool = false
    fileprivate var significantRotation:Bool = false
    
    //active area is in between the small and large radii
    fileprivate var smallRadius:CGFloat?
    fileprivate var largeRadius:CGFloat?
    
    // tracking touch points to determine circle or not circle
    fileprivate var touchPoints = [CGPoint]()
    
    // information about how circle-like is the path
    fileprivate var fitResult = CircleResult()
    fileprivate var isCircle = false
    
    // circle wiggle room (original 0.2)
    fileprivate var tolerance: CGFloat = 0.2
    
    // running CGPath
    fileprivate var path:CGMutablePath? = nil
    
    fileprivate let debug:Bool = false
    
    //MARK: - INIT

    public func setActiveArea(withSmallRadius:CGFloat, andLargeRadius:CGFloat) {
        
        smallRadius = withSmallRadius
        largeRadius = andLargeRadius
    
    }
    
    //MARK: - ACCESSORS
    internal func isTouchInOuterCircleCZone() -> Bool {
        return touchInOuterCircleCZone
    }
    internal func isRotationSignificant() -> Bool {
        return significantRotation
    }
    internal func didTouchBeginInOuterCircleCZone() -> Bool {
        return touchBeganInOuterCircleCZone
    }
    
    //MARK: - TOUCHES
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        
        // if this is a multi touch, then bail
        if touches.count != 1 {
            state = .failed
            return
        }
        
        //reset each touch
        reset()
        
        //get touch point
        let touch:UITouch = (event.allTouches!.first)!
        let touchPoint:CGPoint = touch.location(in: self.view)
        
        //start path
        path = nil
        path = CGMutablePath()
        path!.move(to: CGPoint(x: touchPoint.x, y:touchPoint.y))
        
        //perform hit tests
        if (smallRadius != nil && largeRadius != nil){
            
            touchInOuterCircleCZone = _hitTest(
                touchPoint: touchPoint,
                smallRadius: smallRadius!,
                largeRadius: largeRadius!
            )
            
            touchBeganInOuterCircleCZone = touchInOuterCircleCZone
            
            //update state
            state = .began
            
            if (debug){
                print("CIRCLE: began")
            }
            
        } else {
            
            //error
            print("CIRCLE: Error: No small or large radii has been set during touches began")
            state = .failed
        }
        
    }
    
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        
        // if this is a multi touch, then bail
        if touches.count != 1 {
            state = .failed
            return
        }
        
        //get touch point
        let touch:UITouch = (event.allTouches!.first)!
        let touchPoint:CGPoint = touch.location(in: self.view)
        
        //init avg point
        var averagePoint = CGPoint(x: 0, y: 0)
        
        //update gesture angle
        let lastGestureAngle:Double = gestureAngle
        
        //record curr touch point to array
        touchPoints.append(touchPoint)
        
        //tally up all the existing touchpoints of this sweep
        for tp in touchPoints {
            averagePoint.x += tp.x
            averagePoint.y += tp.y
        }
        
        //grab count
        let touchPointsCount = CGFloat(touchPoints.count)
        
        //get average of all points in sweep
        averagePoint.x = averagePoint.x / touchPointsCount
        averagePoint.y = averagePoint.y / touchPointsCount
        
        //crunch the numbers to get angle
        let dx = Double(averagePoint.x - touchPoint.x)
        let dy = Double(averagePoint.y - touchPoint.y)
        gestureAngle = atan2(dy, dx) * (180.0 / Double.pi)
        
        // alter rotation counter
        // subtracting is counterclockwise
        // adding is clockwise
        if (gestureAngle < lastGestureAngle){
            rotationCounter -= 1
            rotationDirection = .rotationCounterClockwise
        } else {
            rotationCounter += 1
            rotationDirection = .rotationClockwise
        }
        
        //update path
        if (path != nil) {
            path!.addLine(to: CGPoint(x:touchPoint.x, y:touchPoint.y))
        } else {
            print("CIRCLE: path is nil in touchesMoved")
        }
        
        
        //perform hit tests
        //is touch still inside the hit zone
        //perform hit tests
        if (smallRadius != nil && largeRadius != nil){
            
            touchInOuterCircleCZone = _hitTest(
                touchPoint: touchPoint,
                smallRadius: smallRadius!,
                largeRadius: largeRadius!
            )
            
            // check to see if rotation amount is signicant
            // only use significant amounts to change the interface
            if (rotationCounter > SIGNICANT_ROTATION_RANGE ||
                rotationCounter < -SIGNICANT_ROTATION_RANGE) {
                significantRotation = true
            } else {
                significantRotation = false
            }
            
            if (debug){
                print("CIRCLE: gesture angle =", gestureAngle)
            }
            
            //update state
            state = .changed
            
        } else {
            
            //error
            print("CIRCLE: Error: No small or large radii has been set during touches moved")
            state = .failed
        }
        
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        
        if touches.count != 1 {
            state = .failed
            return
        }
        
        touchInOuterCircleCZone = false
        
        state = .ended
        
        // now that the user has stopped touching, figure out if the path was a circle
        fitResult = fitCircle(points:touchPoints)
        
        // make sure there are no points in the middle of the circle
        let hasInside = _anyPointsInTheMiddle()
        
        //how close is it to a circle?
        var percentOverlap:CGFloat = 0
        
        if (path != nil){
            percentOverlap = calculateBoundingOverlap()
        } else {
            print("CIRCLE: path is nil in touchesEnded")
        }
        
        //do comparison to see if it is a circle
        isCircle = fitResult.error <= tolerance && !hasInside && percentOverlap > (1-tolerance)
        
        //if it is, then see if it was clockwise or counter clockwise
        
        if (isCircle){
            
            if (rotationCounter < 0){
                
                rotationDirection = .rotationCounterClockwise
                
            } else {
                
                rotationDirection = .rotationClockwise
                
            }
            
        } else {
            
            rotationDirection = .rotationUnknown
            state = .failed
            
        }
        
        if (debug){
            print("CIRCLE: ended, state =", state, "direction =", rotationDirection)
        }
        
        path = nil
        
    }
    
    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        
        // forward the cancel state
        state = .cancelled
        
    }
    
    //MARK: - RESET
    override public func reset() {
        
        //super.reset()
        touchPoints.removeAll(keepingCapacity: true)
        path = nil
        isCircle = false
        significantRotation = false
        touchInOuterCircleCZone = false
        touchBeganInOuterCircleCZone = false
        state = .possible
        rotationDirection = .rotationUnknown
        rotationCounter = 0
        
    }
    
    //MARK-
    //MARK: PRIVATE
    fileprivate func _anyPointsInTheMiddle() -> Bool {
        // 1
        let fitInnerRadius = fitResult.radius / sqrt(2) * tolerance
        // 2
        let innerBox = CGRect(
            x: fitResult.center.x - fitInnerRadius,
            y: fitResult.center.y - fitInnerRadius,
            width: 2 * fitInnerRadius,
            height: 2 * fitInnerRadius)
        
        // 3
        var hasInside = false
        for point in touchPoints {
            if innerBox.contains(point) {
                hasInside = true
                break
            }
        }
        
        return hasInside
    }
    
    fileprivate func calculateBoundingOverlap() -> CGFloat {
        
        let fitBoundingBox = CGRect(
            x: fitResult.center.x - fitResult.radius,
            y: fitResult.center.y - fitResult.radius,
            width: 2 * fitResult.radius,
            height: 2 * fitResult.radius)
        let pathBoundingBox = path!.boundingBox
        
        let overlapRect = fitBoundingBox.intersection(pathBoundingBox)
        let overlapRectArea = overlapRect.width * overlapRect.height
        let circleBoxArea = fitBoundingBox.height * fitBoundingBox.width
        
        let percentOverlap = overlapRectArea / circleBoxArea
        
        return percentOverlap
        
    }
    
    //hit test
    fileprivate func _hitTest(touchPoint:CGPoint, smallRadius:CGFloat, largeRadius:CGFloat) -> Bool {
        
        let centerPoint:CGPoint = CGPoint(
            x: UIScreen.main.bounds.width / 2,
            y: UIScreen.main.bounds.height / 2)
        
        let smallCircle:Circle = Circle(centerPoint: centerPoint, radius: smallRadius)
        let largeCircle:Circle = Circle(centerPoint: centerPoint, radius: largeRadius)
        
        return Utils.testIs(point: touchPoint,
                                  betweenSmallCircle: smallCircle,
                                  andLargeCircle: largeCircle)
        
    }
    
    
}


