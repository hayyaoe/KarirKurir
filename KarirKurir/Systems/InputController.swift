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
    private let minimumDistance: CGFloat = 15.0
    private let minimumVelocity: CGFloat = 80.0
    private var lastNotifiedDirection: MoveDirection?
    private var initialTouchPoint: CGPoint = .zero
    private var lastTranslation: CGPoint = .zero
    private var directionLockThreshold: CGFloat = 30.0
    
    init(view: SKView) {
        setupGestures(view: view)
    }
    
    private func setupGestures(view: SKView) {
        // Pan gesture for continuous swiping
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(sender:)))
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        panGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(panGesture)
        
        // Tap gesture for quick direction changes
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        tapGesture.numberOfTapsRequired = 1
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
        switch sender.state {
        case .began:
            initialTouchPoint = sender.location(in: sender.view)
            lastTranslation = .zero
            print("Pan began at: \(initialTouchPoint)")
            
        case .changed:
            let currentTranslation = sender.translation(in: sender.view)
            let velocity = sender.velocity(in: sender.view)
            
            // Calculate the delta from last translation for smoother control
            let deltaTranslation = CGPoint(
                x: currentTranslation.x - lastTranslation.x,
                y: currentTranslation.y - lastTranslation.y
            )
            
            let newDirection = getDirectionFromInput(
                velocity: velocity,
                translation: currentTranslation,
                deltaTranslation: deltaTranslation
            )
            
            // Update direction if it changed significantly
            if let newDirection = newDirection, shouldUpdateDirection(to: newDirection) {
                lastNotifiedDirection = newDirection
                onDirectionChange?(newDirection)
                print("Direction changed to: \(newDirection.description)")
                
                // Reset translation reference after direction change
                sender.setTranslation(.zero, in: sender.view)
                lastTranslation = .zero
            } else {
                lastTranslation = currentTranslation
            }
            
        case .ended, .cancelled:
            print("Pan ended")
            // Don't reset lastNotifiedDirection to maintain movement
            
        default:
            break
        }
    }
    
    private func getDirectionFromInput(velocity: CGPoint, translation: CGPoint, deltaTranslation: CGPoint) -> MoveDirection? {
        let absVelX = abs(velocity.x)
        let absVelY = abs(velocity.y)
        let absTransX = abs(translation.x)
        let absTransY = abs(translation.y)
        
        // Check if movement is significant enough
        let hasSignificantVelocity = max(absVelX, absVelY) > minimumVelocity
        let hasSignificantTranslation = max(absTransX, absTransY) > minimumDistance
        
        guard hasSignificantVelocity || hasSignificantTranslation else {
            return nil
        }
        
        // Prioritize velocity for immediate response, fall back to translation
        let primaryX: CGFloat
        let primaryY: CGFloat
        
        if hasSignificantVelocity {
            primaryX = velocity.x
            primaryY = -velocity.y // Flip Y for SpriteKit coordinates
        } else {
            primaryX = translation.x
            primaryY = -translation.y // Flip Y for SpriteKit coordinates
        }
        
        // Determine direction with better diagonal handling
        let absX = abs(primaryX)
        let absY = abs(primaryY)
        
        // Add some bias to prevent too frequent direction changes
        let bias: CGFloat = 1.2
        
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
    
    private func shouldUpdateDirection(to newDirection: MoveDirection) -> Bool {
        // Always allow first direction
        guard let lastDirection = lastNotifiedDirection else { return true }
        
        // Don't change if it's the same direction
        if newDirection == lastDirection { return false }
        
        // Allow opposite direction changes (for quick reversals)
        if newDirection == getOppositeDirection(lastDirection) { return true }
        
        // Allow perpendicular changes (for turns)
        if isPerpendicularDirection(newDirection, to: lastDirection) { return true }
        
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
}

// Extension to make MoveDirection printable for debugging
extension MoveDirection {
    var description: String {
        switch self {
        case .up: return "up"
        case .down: return "down"
        case .left: return "left"
        case .right: return "right"
        }
    }
}
