//
//  Fish.swift
//  Gone Fishing
//
//  Created by Arden Kolodner on 8/3/23.
//

import ScreenSaver

class Fish {
    private let parent: GoneFishingView
    
    private static let assets = Bundle.init(identifier: "com.ardenkolodner.Gone-Fishing")
    public static let fishImgs: [NSImage?] = [
        MediaLoader.loadImage("fish_simple_outlined"),
        MediaLoader.loadImage("fish_barrango"),
        MediaLoader.loadImage("fish_chromis_viridis"),
        MediaLoader.loadImage("fish_clownfish"),
        MediaLoader.loadImage("fish_ghost"),
        MediaLoader.loadImage("fish_minnow"),
        MediaLoader.loadImage("fish_redorange"),
        MediaLoader.loadImage("fish_yellowwavy"),
    ]
    
    private let textureIndex: Int
    
    public var position: CGPoint
    private var rotation: CGFloat = 0
    
    private var entrySpeed: CGFloat = 1
    private var speed: CGFloat = 1
    
    private let swimInThreshold: CGFloat = 100
    private let maxSpeed: CGFloat = 5
    
    private var swimBAFvarianceInterval = 600
    private var swimBAFvarianceTimer: Int
    
    private var currentBehavior: FishBehavior
    
    private var goForHookDistance: CGFloat = 150
    private var onHookThreshold: CGFloat = 10
    
    private let turnSpeed: CGFloat = 3
    
//    private let drawOffset = CGPoint(x: -60, y: -30)
//    private let drawOffsetFlipped = CGPoint(x: -10, y: -30)
    
    private var display = NSString("")
        
    convenience init(pos: CGPoint, parent: GoneFishingView) {
        self.init(Int.random(in: 0...Fish.fishImgs.count-1), pos: pos, parent: parent)
    }
    
    init(_ texture: Int, pos: CGPoint, parent: GoneFishingView) {
        self.parent = parent
        
        if (texture < 0 || texture >= Fish.fishImgs.count) {
            print("Invalid fish texture number " + String(texture))
            textureIndex = 0
        } else {
            textureIndex = texture
        }
        
        position = pos
        
        currentBehavior = .Swim
        
        swimBAFvarianceInterval += Int.random(in: -30 ... 30)
        swimBAFvarianceTimer = Int.random(in: 0 ... swimBAFvarianceInterval)
    }
    
    private func drawPosition() -> CGPoint {
        let r = Fish.fishImgs[textureIndex]!.size.width

        if isFlipped() {return CGPoint(x: position.x - r, y: position.y - r)}
        return CGPoint(x: position.x - r, y: position.y - r)
    }
    
    public func getTextureIndex() -> Int {return textureIndex}
    
    public func draw() {
        switch currentBehavior {
        case .SwimOut: fallthrough
        case .Swim:
            let img = Fish.fishImgs[textureIndex]!.rotateFishByDegrees(degrees: rotation, isFlipped: isFlipped())
            let imgRect = NSRect(origin: drawPosition(), size: img.size)
            
            img.draw(in: imgRect)
            break
        case .OnHook:
            let img = Fish.fishImgs[textureIndex]!.rotateFishByDegrees(degrees: 90, isFlipped: false)
            let imgRect = NSRect(origin: drawPosition(), size: img.size)
            img.draw(in: imgRect)
            break
        case .PursueHook:
            let img = Fish.fishImgs[textureIndex]!.rotateFishByDegrees(degrees: rotation, isFlipped: isFlipped())
            let imgRect = NSRect(origin: drawPosition(), size: img.size)
            img.draw(in: imgRect)
            break
        }
        
        if displayFishDirections {
            let vecAlongRotation = CGVector(dx: cos(rotation * toRadians), dy: sin(rotation * toRadians))
            let p1 = NSBezierPath()
            p1.move(to: position)
            p1.line(to: CGPoint(x: position.x + vecAlongRotation.dx * 10, y: position.y + vecAlongRotation.dy * 10))
            NSColor.red.withAlphaComponent(0.5).setStroke()
            p1.stroke()
            let p2 = NSBezierPath()
            p2.move(to: CGPoint(x: position.x + vecAlongRotation.dx * 10, y: position.y + vecAlongRotation.dy * 10))
            p2.line(to: CGPoint(x: position.x + vecAlongRotation.dx * 20, y: position.y + vecAlongRotation.dy * 20))
            NSColor.red.setStroke()
            p2.stroke()
            
            if currentBehavior == .PursueHook {
                let hookPos = parent.visualHookPos()
                let vecToHook = CGVector(dx: hookPos!.x - position.x, dy: hookPos!.y - position.y)
                
                let magnitude = sqrt(pow(vecToHook.dx, 2) + pow(vecToHook.dy, 2))
                let vecToHook_norm = CGVector(dx: vecToHook.dx / magnitude, dy: vecToHook.dy / magnitude)
                
                let p4 = NSBezierPath()
                p4.move(to: position)
                p4.line(to: CGPoint(x: position.x + vecToHook_norm.dx * 10, y: position.y + vecToHook_norm.dy * 10))
                NSColor.yellow.withAlphaComponent(0.5).setStroke()
                p4.stroke()
                let p3 = NSBezierPath()
                p3.move(to: CGPoint(x: position.x + vecToHook_norm.dx * 10, y: position.y + vecToHook_norm.dy * 10))
                p3.line(to: CGPoint(x: position.x + vecToHook_norm.dx * 20, y: position.y + vecToHook_norm.dy * 20))
                NSColor.yellow.setStroke()
                p3.stroke()
            }
        }
        
        if display.length > 0 {
            let str = display//NSString(format: "%.1f", rotation)
            str.draw(at: CGPoint(x: position.x, y: position.y + 100))
        }
    }
    
    public func animate() {
        if currentBehavior != .OnHook {
            let vecAlongRotation = CGVector(dx: cos(rotation * toRadians), dy: sin(rotation * toRadians))
            position.x += vecAlongRotation.dx * abs(speed)
            position.y += vecAlongRotation.dy * abs(speed)
        }
        
        switch currentBehavior {
        case .OnHook:
            let p = parent.visualHookPos()
            if p != nil {
                position = p!
            }
            break
        case .PursueHook:
            let hookPos = parent.visualHookPos()
            if hookPos == nil {
                currentBehavior = .Swim
                break
            }
            
            let vecToHook = CGVector(dx: hookPos!.x - position.x, dy: hookPos!.y - position.y)
            
            var rotationTowardsHook = atan(vecToHook.dy / vecToHook.dx)
            if vecToHook.dx < 0 {
                rotationTowardsHook += .pi
            }
            
            if rotationTowardsHook < 0 {
                rotationTowardsHook += 2 * .pi
            }
            
            var diffFromHook = abs(rotationTowardsHook * toDegrees - rotation)
            if diffFromHook > 180 {diffFromHook = 360 - diffFromHook}

            if abs(rotationTowardsHook * toDegrees - rotation) < turnSpeed {
                speed += 0.05 // Fish is excited! Go straight ahead!
                speed *= 0.99
            } else if diffFromHook > 100 {
                rotation += 180
                if rotation > 360 {rotation -= 360}
            } else {
                // Turn towards hook
                var temp_rotation = rotation * toRadians
                while temp_rotation > rotationTowardsHook {temp_rotation -= 2 * .pi}
                
                let angle_left = abs(rotationTowardsHook - temp_rotation)
                let angle_right = 2 * .pi - angle_left
                
                if angle_left < angle_right {
                    rotation += turnSpeed
                    if rotation > 360 {rotation -= 360}
                } else {
                    rotation -= turnSpeed
                    if rotation < 0 {rotation += 360}
                }
            }
            
            checkHook()
            break
        case .Swim:
            swimBAFvarianceTimer += 1

            if swimBAFvarianceTimer >= swimBAFvarianceInterval {
                speed += CGFloat.random(in: -1 ... 1)
                swimBAFvarianceTimer = 0

                if speed < 0 {
                    speed = abs(speed)
                    rotation += 180
                    if rotation > 360 {rotation -= 360}
                }
            }
            
            speed *= 0.99
            if speed < 0.6 {
                speed = CGFloat.random(in: 1 ... 3)
                
                if position.x < swimInThreshold {
                    rotation = 0
                } else if position.x > parent.getFrame().width - swimInThreshold {
                    rotation = 180
                } else {
                    // More likely to swim towards hook, or center if no hook: 1/5 left, 1/5 right, 3/5 towards hook/center
                    let directionChoice = Int.random(in: 1...5)
                    if directionChoice == 1 {rotation = 0}
                    else if directionChoice == 2 {rotation = 180}
                    else {
                        let targetX: CGFloat
                        if (parent.visualHookPos() != nil) {targetX = parent.visualHookPos()!.x}
                        else {targetX = parent.getFrame().width/2}
                        rotation = (targetX - position.x > 0) ? 0 : 180
                    }
                }
            }

            if abs(speed) > maxSpeed {
                speed = maxSpeed
            }
            
            checkHook()
            break
    case .SwimOut:
        speed *= 0.99
        if speed < 0.6 {
            speed = CGFloat.random(in: 2 ... 4)
        }
        if abs(speed) > maxSpeed {
            speed = maxSpeed
        }
            
        break
        }
    }
    
    public func isFlipped() -> Bool {
        if rotation < 90 || rotation > 270 {
            return false
        }
        return true
    }
    
    public func onHook() -> Bool {
        return currentBehavior == .OnHook
    }
    
    public func beginDespawn() {
        if rotation < 90 || rotation > 270 {rotation = 0} else {rotation = 180}
        currentBehavior = .SwimOut
    }
    
    private func checkHook() {
        if parent.getPhase() != .ThrowHook {
            if currentBehavior == .PursueHook {
                currentBehavior = .Swim
            }
            return
        }
        
        if currentBehavior != .PursueHook {
            let hookPos = parent.visualHookPos()
            if hookPos == nil {return}
            let distFromHook = sqrt(pow(hookPos!.x - position.x, 2) + pow(hookPos!.y - position.y, 2))
            
            if distFromHook < goForHookDistance {
                currentBehavior = .PursueHook
            }
        } else {
            let hookPos = parent.visualHookPos()
            if hookPos == nil {
                currentBehavior = .Swim
                if rotation < 90 || rotation > 270 {rotation = 0}
                else {rotation = 180}
                
                return
            }
            let distFromHook = sqrt(pow(hookPos!.x - position.x, 2) + pow(hookPos!.y - position.y, 2))
            
            if distFromHook > goForHookDistance {
                currentBehavior = .Swim
                if rotation < 90 || rotation > 270 {rotation = 0}
                else {rotation = 180}
                
                return
            } else if distFromHook < onHookThreshold {
                currentBehavior = .OnHook
                parent.notifyOnHook()
                return
            }
        }
    }
}
