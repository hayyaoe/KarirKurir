//
//  InputController.swift
//  KarirKurir
//

import UIKit
import SpriteKit

class InputController {
    var onDirectionChange: ((MoveDirection?) -> Void)?
    
    private var panGesture: UIPanGestureRecognizer!
    private var tapGesture: UITapGestureRecognizer!
    private var currentDirection: MoveDirection?
    
    // ENHANCED: Adaptive thresholds for better responsiveness at all speeds
    private let baseMinimumDistance: CGFloat = 8.0  // Even more responsive
    private let baseMinimumVelocity: CGFloat = 40.0 // More responsive
    private let maximumDistance: CGFloat = 150.0    // Don't require huge swipes
    private let maximumSwipeTime: TimeInterval = 0.6 // Allow slower swipes
    
    private var lastNotifiedDirection: MoveDirection?
    private var initialTouchPoint: CGPoint = .zero
    private var lastTranslation: CGPoint = .zero
    private var directionLockThreshold: CGFloat = 20.0 // More responsive turns
    private var isFirstSwipe: Bool = true
    
    // ENHANCED: Speed tracking for adaptive detection
    private var gestureStartTime: TimeInterval = 0
    private var lastUpdateTime: TimeInterval = 0
    
    init(view: SKView) {
        setupGestures(view: view)
    }
    
    private func setupGestures(view: SKView) {
        // Pan gesture for continuous swiping - ENHANCED for responsiveness
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(sender:)))
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        panGesture.cancelsTouchesInView = false
        panGesture.delaysTouchesBegan = false
        panGesture.delaysTouchesEnded = false
        view.addGestureRecognizer(panGesture)
        
        // Tap gesture for quick direction changes - ENHANCED
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.delaysTouchesBegan = false
        tapGesture.delaysTouchesEnded = false
        tapGesture.require(toFail: panGesture)
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleTap(sender: UITapGestureRecognizer) {
        // Quick tap to reverse direction or stop
        if let currentDir = lastNotifiedDirection {
            let oppositeDirection = getOppositeDirection(currentDir)
            lastNotifiedDirection = oppositeDirection
            onDirectionChange?(oppositeDirection)
            print("Quick tap - reversed direction to: \(oppositeDirection.description)")
        }
    }
    
    @objc private func handlePan(sender: UIPanGestureRecognizer) {
        let currentTime = CACurrentMediaTime()
        
        switch sender.state {
        case .began:
            initialTouchPoint = sender.location(in: sender.view)
            lastTranslation = .zero
            gestureStartTime = currentTime
            lastUpdateTime = currentTime
            print("Pan began at: \(initialTouchPoint)")
            
        case .changed:
            let currentTranslation = sender.translation(in: sender.view)
            let velocity = sender.velocity(in: sender.view)
            
            // ENHANCED: Calculate gesture timing for adaptive detection
            let gestureTime = currentTime - gestureStartTime
            let deltaTime = currentTime - lastUpdateTime
            
            // Calculate the delta from last translation for smoother control
            let deltaTranslation = CGPoint(
                x: currentTranslation.x - lastTranslation.x,
                y: currentTranslation.y - lastTranslation.y
            )
            
            // ENHANCED: Get direction with adaptive thresholds
            let newDirection = getDirectionFromInputEnhanced(
                velocity: velocity,
                translation: currentTranslation,
                deltaTranslation: deltaTranslation,
                gestureTime: gestureTime,
                deltaTime: deltaTime
            )
            
            // Update direction if it changed significantly
            if let newDirection = newDirection, shouldUpdateDirection(to: newDirection) {
                lastNotifiedDirection = newDirection
                onDirectionChange?(newDirection)
                print("Direction changed to: \(newDirection.description) (gesture time: \(String(format: "%.3f", gestureTime))s)")
                
                // Reset translation reference after direction change
                sender.setTranslation(.zero, in: sender.view)
                lastTranslation = .zero
                gestureStartTime = currentTime // Reset timing for next direction
                
                // Mark that first swipe has happened
                isFirstSwipe = false
            } else {
                lastTranslation = currentTranslation
            }
            
            lastUpdateTime = currentTime
            
        case .ended, .cancelled:
            print("Pan ended (duration: \(String(format: "%.3f", currentTime - gestureStartTime))s)")
            // Don't reset lastNotifiedDirection to maintain movement
            
        default:
            break
        }
    }
    
    // ENHANCED: Adaptive direction detection that works at all speeds
    private func getDirectionFromInputEnhanced(
        velocity: CGPoint,
        translation: CGPoint,
        deltaTranslation: CGPoint,
        gestureTime: TimeInterval,
        deltaTime: TimeInterval
    ) -> MoveDirection? {
        
        let absVelX = abs(velocity.x)
        let absVelY = abs(velocity.y)
        let absTransX = abs(translation.x)
        let absTransY = abs(translation.y)
        
        // ENHANCED: Adaptive thresholds based on gesture characteristics
        var adaptiveMinDistance = baseMinimumDistance
        var adaptiveMinVelocity = baseMinimumVelocity
        
        // Make first swipe extra responsive
        if isFirstSwipe {
            adaptiveMinDistance *= 0.6  // 60% of normal threshold
            adaptiveMinVelocity *= 0.7  // 70% of normal threshold
            print("First swipe - using reduced thresholds: dist=\(adaptiveMinDistance), vel=\(adaptiveMinVelocity)")
        }
        
        // ENHANCED: Speed-independent detection
        // For slow swipes, rely more on distance; for fast swipes, rely more on velocity
        let gestureSpeed = max(absVelX, absVelY)
        let gestureDistance = max(absTransX, absTransY)
        
        // Adaptive threshold based on swipe characteristics
        if gestureTime > 0.3 {
            // Slow swipe - be more lenient with distance requirements
            adaptiveMinDistance = max(adaptiveMinDistance * 0.7, 5.0)
            print("Slow swipe detected - reduced distance threshold to \(adaptiveMinDistance)")
        }
        
        if gestureTime < 0.15 {
            // Fast swipe - be more lenient with velocity requirements
            adaptiveMinVelocity = max(adaptiveMinVelocity * 0.8, 30.0)
            print("Fast swipe detected - reduced velocity threshold to \(adaptiveMinVelocity)")
        }
        
        // Check if movement is significant enough
        let hasSignificantVelocity = gestureSpeed > adaptiveMinVelocity
        let hasSignificantTranslation = gestureDistance > adaptiveMinDistance
        
        // ENHANCED: Also check for reasonable gesture timing
        let hasReasonableTiming = gestureTime <= maximumSwipeTime
        
        guard (hasSignificantVelocity || hasSignificantTranslation) && hasReasonableTiming else {
            if !hasReasonableTiming {
                print("Gesture too slow: \(String(format: "%.3f", gestureTime))s > \(maximumSwipeTime)s")
            }
            return nil
        }
        
        // ENHANCED: Intelligent input prioritization
        let primaryX: CGFloat
        let primaryY: CGFloat
        
        // For very fast swipes, prioritize velocity
        // For slower swipes, blend velocity and translation
        if gestureSpeed > adaptiveMinVelocity * 2.0 {
            // Fast swipe - use velocity
            primaryX = velocity.x
            primaryY = -velocity.y // Flip Y for SpriteKit coordinates
            print("Using velocity for fast swipe: (\(primaryX), \(primaryY))")
        } else if gestureDistance > adaptiveMinDistance * 1.5 {
            // Deliberate swipe - use translation
            primaryX = translation.x
            primaryY = -translation.y // Flip Y for SpriteKit coordinates
            print("Using translation for deliberate swipe: (\(primaryX), \(primaryY))")
        } else {
            // Balanced approach - blend both
            let velocityWeight: CGFloat = min(gestureSpeed / (adaptiveMinVelocity * 2.0), 1.0)
            let translationWeight: CGFloat = 1.0 - velocityWeight
            
            primaryX = velocity.x * velocityWeight + translation.x * translationWeight
            primaryY = (-velocity.y) * velocityWeight + (-translation.y) * translationWeight
            print("Blended input: vel_weight=\(String(format: "%.2f", velocityWeight)), result=(\(primaryX), \(primaryY))")
        }
        
        // ENHANCED: Direction determination with adaptive bias
        let absX = abs(primaryX)
        let absY = abs(primaryY)
        
        // Adaptive bias - less bias for first swipe to be more responsive
        let bias: CGFloat = isFirstSwipe ? 1.1 : 1.3
        
        if absX > absY * bias {
            return primaryX > 0 ? .right : .left
        } else if absY > absX * bias {
            return primaryY > 0 ? .up : .down
        } else {
            // For diagonal movement, prefer the stronger component
            if absX > absY {
                return primaryX > 0 ? .right : .left
            } else {
                return primaryY > 0 ? .up : .down
            }
        }
    }
    
    // ENHANCED: Smarter direction update logic
    private func shouldUpdateDirection(to newDirection: MoveDirection) -> Bool {
        // Always allow first direction
        guard let lastDirection = lastNotifiedDirection else {
            print("First direction allowed: \(newDirection.description)")
            return true
        }
        
        // Don't change if it's the same direction
        if newDirection == lastDirection {
            return false
        }
        
        // ENHANCED: More responsive direction changes
        // Allow opposite direction changes (for quick reversals)
        if newDirection == getOppositeDirection(lastDirection) {
            print("Opposite direction change: \(lastDirection.description) -> \(newDirection.description)")
            return true
        }
        
        // Allow perpendicular changes (for turns)
        if isPerpendicularDirection(newDirection, to: lastDirection) {
            print("Perpendicular direction change: \(lastDirection.description) -> \(newDirection.description)")
            return true
        }
        
        // ENHANCED: For first few swipes, be more lenient
        if isFirstSwipe {
            print("First swipe - allowing direction change: \(lastDirection.description) -> \(newDirection.description)")
            return true
        }
        
        return false
    }
    
    private func getOppositeDirection(_ direction: MoveDirection) -> MoveDirection {
        switch direction {
        case .up: return .down
        case .down: return .up
        case .left: return .right
        case .right: return .left
        }
    }
    
    private func isPerpendicularDirection(_ direction1: MoveDirection, to direction2: MoveDirection) -> Bool {
        let horizontalDirections: Set<MoveDirection> = [.left, .right]
        let verticalDirections: Set<MoveDirection> = [.up, .down]
        
        return (horizontalDirections.contains(direction1) && verticalDirections.contains(direction2)) ||
               (verticalDirections.contains(direction1) && horizontalDirections.contains(direction2))
    }
    
    // Reset for game restart - ENHANCED
    func reset() {
        lastNotifiedDirection = nil
        currentDirection = nil
        isFirstSwipe = true
        gestureStartTime = 0
        lastUpdateTime = 0
        lastTranslation = .zero
        print("InputController reset - ready for responsive input")
    }
}
