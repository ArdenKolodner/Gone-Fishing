//
//  GoneFishing.swift
//  Gone Fishing
//
//  Created by Arden Kolodner on 6/19/23. Happy Juneteenth!
//

//    private let assets: Bundle? = Bundle.main

import ScreenSaver

let toRadians = .pi / CGFloat(180)
let toDegrees = CGFloat(180) / .pi

let displayFishDirections = false

enum Phase {
    case Delay
    case ThrowHook
    case ReelIn
    case SwitchShip
}

enum FishBehavior {
    case Swim
    case PursueHook
    case OnHook
    case SwimOut
}

class GoneFishingView: ScreenSaverView {
    private let assets = Bundle.init(identifier: "com.ardenkolodner.Gone-Fishing")
    private let boatImgs: [NSImage?]
    private var boatImgIndex: Int = 0
    private let hookImg: NSImage?
    
    private var hookPos: CGPoint?
    private var hookVel: CGVector?
    public func visualHookPos() -> CGPoint? {
        if hookPos == nil {return nil}
        return CGPoint(x: hookPos!.x + hookOffset.dx, y: hookPos!.y + hookOffset.dy)
    }
    
    private var phase: Phase
    
    private var waterLevel: CGFloat
    
    private var gravity: CGFloat = 0.5
    private var underwaterSpeed: CGFloat = 7
    private var waterDragCoefficient: CGFloat = 0.9
    
    private let reelBackThreshold: CGFloat = 5
    
    private var fisherOffsets = [
        CGVector(dx: 75, dy: 30),
        CGVector(dx: 220, dy: 50),
        CGVector(dx: 220, dy: 50)
    ]
    
    private var boatOffsets = [
        CGPoint(x: 0, y: -25),
        CGPoint(x: 0, y: -25),
        CGPoint(x: 0, y: -25)
    ]
    
    private var stringOffset = CGVector(dx: 8, dy: 12)
    private var hookOffset = CGVector(dx: 8, dy: 8)
    
    private var wasUnderwaterLast = false
    private var wasUnderwaterBefore = false
    private var timesUnderwater = 0
    
    private var DELAY_LENGTH_SEC = 1
    private var SWITCH_LENGTH_SEC = 3
    
    private var delayStart: Date?
    private var reelInStart = Date()
    
    private var clouds: [Cloud]
    
    private let water: SimulatedWater
    
    private var fish: [Fish]
    private var fishToDespawn: Int?
    private var fishSpawnEventTimer: Date?
    private var fishSpawnEventInterval: CGFloat = 10
    
    public var counterUpperLimit: CGFloat = 1000
    public var counterLowerLimit: CGFloat = 400
    public var counterMargin: CGFloat = 200
    
    private var counters: [FishCountView]
    
    private var totalFishCaught = 0
    
    private let skyColor = NSColor(red: 0.52, green: 0.81, blue: 0.92, alpha: 1)
    private let oceanColor = NSColor(red: 0.03, green: 0.23, blue: 0.81, alpha: 1)
    
    public func getFrame() -> NSRect {return frame}
    
    public func getPhase() -> Phase {return phase}
    
    // MARK: - Initialization
    override init?(frame: NSRect, isPreview: Bool) {
        counterUpperLimit = 5 * frame.height / 6
        counterLowerLimit = frame.height / 6
        counterMargin = frame.height / 5
        
        boatImgs = [
            assets?.image(forResource: "sailboat"),
            assets?.image(forResource: "galleon"),
            assets?.image(forResource: "galleon_insignia")
        ]
        hookImg = assets?.image(forResource: "fishhook")
        
        phase = Phase.Delay
        delayStart = nil
        
        waterLevel = frame.height / 2
        
        clouds = []
        
        fish = []
        
        counters = []
        
        water = SimulatedWater(frame: frame, waterLevel: waterLevel, waterColor: oceanColor)
    
        super.init(frame: frame, isPreview: isPreview)
        
        var yPos = 600
        for i in 0 ... Fish.fishImgs.count-1 {
            counters.append(FishCountView(index: i, pos: CGPoint(x: 50, y: yPos), parent: self))
            yPos -= 100
        }
        
        let numClouds = Int.random(in: 7...12)
        for i in 1...numClouds {
            let c = Cloud(pos: randomCloudPos())
            c.position.x = frame.width * CGFloat(i) / CGFloat(numClouds)
            clouds.append(c)
        }
        
        let numFish = Int.random(in: 5...20)
        for _ in 1...numFish {
            var pos = randomFishPos()
            pos.x = CGFloat.random(in: 0...frame.width)
            let f = Fish(pos: pos, parent: self)
            fish.append(f)
        }
    }
    
    private func randomVelocity() -> CGVector {
        let dvm: CGFloat = CGFloat.random(in: 8 ... 30) // desired velocity magnitude
        let xVelocity = CGFloat.random(in: (dvm / 6) ... (5 * dvm / 6))
        let yVelocity = sqrt(pow(dvm, 2) - pow(xVelocity, 2))
        return CGVector(dx: xVelocity, dy: yVelocity)
    }

    @available(*, unavailable)
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func stringPos() -> CGPoint {
        return CGPoint(x: hookPos!.x + stringOffset.dx, y: hookPos!.y + stringOffset.dy)
    }
    
    public func fisherPos() -> CGPoint {
        let p = getBoatPos()
        return CGPoint(
            x: p.x + fisherOffsets[boatImgIndex].dx,
            y: p.y + fisherOffsets[boatImgIndex].dy
        )
    }
    
    func getBoatPos() -> CGPoint {
//        var basePos = CGPoint(x: frame.width / 6, y: waterLevel - boatImgs[boatImgIndex]!.size.height / 4)
//
//        if (boatImgIndex >= 1 && boatImgIndex <= 2) {
//            basePos.y += boatImgs[boatImgIndex]!.size.height / 8
//        }
//
//        return basePos
        return CGPoint(
            x: water.getPtPos(index: 10).x + boatOffsets[boatImgIndex].x,
            y: water.getPtPos(index: 10).y + boatOffsets[boatImgIndex].y
        )
    }
    
    func getBoatPos(ind: Int) -> CGPoint {
//        var basePos = CGPoint(x: frame.width / 6, y: waterLevel - boatImgs[ind]!.size.height / 4)
//
//        if (ind >= 1 && ind <= 2) {
//            basePos.y += boatImgs[ind]!.size.height / 8
//        }
//
//        return basePos
        return CGPoint(
            x: water.getPtPos(index: 10).x + boatOffsets[boatImgIndex].x,
            y: water.getPtPos(index: 10).y + boatOffsets[boatImgIndex].y
        )
    }
    
    public func notifyOnHook() {
        phase = .ReelIn
        reelInStart = Date.now
    }
    
    private func resetVars() {
        delayStart = nil
        hookPos = nil
        timesUnderwater = 0
        
        if (phase == .Delay || phase == .SwitchShip) {
            delayStart = Date()
        }
    }

    // MARK: - Lifecycle
    override func draw(_ rect: NSRect) {
        // Draw a single frame in this function
//        let oceanRect = NSRect(origin: rect.origin, size: CGSize(width: rect.width, height: rect.height - waterLevel))
//        let skyRect = NSRect(origin: CGPoint(x: rect.origin.x, y: rect.origin.y + waterLevel), size: CGSize(width: rect.width, height: waterLevel))
        let skyRect = rect
        
        let skyPath = NSBezierPath(rect: skyRect)
//        let oceanPath = NSBezierPath(rect: oceanRect)
        
        skyColor.setFill()
        skyPath.fill()
//        oceanColor.setFill()
//        oceanPath.fill()
        water.draw()
        
        for cloud in clouds {
            cloud.draw()
        }
        
        for f in fish {
            f.draw()
        }
        
        for c in counters {
            c.draw()
        }
        
        if hookPos != nil && hookVel != nil {
            let hookRect = NSRect(origin: hookPos!, size: hookImg!.size)
            hookImg!.draw(in: hookRect)
            
            let controlPoint1 = CGPoint(x: 0.5*fisherPos().x + 0.5*hookPos!.x, y: 0.75*fisherPos().y + 0.25*hookPos!.y)
            let controlPoint2 = CGPoint(x: 0.5*fisherPos().x + 0.5*hookPos!.x, y: 0.25*fisherPos().y + 0.75*hookPos!.y)
            let reelPath = NSBezierPath()
            reelPath.move(to: fisherPos())
            reelPath.curve(to: stringPos(), controlPoint1: controlPoint1, controlPoint2: controlPoint2)
            NSColor.white.setStroke()
            reelPath.stroke()
        }
        
        if boatImgs[boatImgIndex] != nil {
            let boatImg = boatImgs[boatImgIndex]
            let boatRect = NSRect(origin: getBoatPos(), size: boatImgs[boatImgIndex]!.size)
            
            if (phase == .SwitchShip && delayStart != nil) {
                let pctDone = Date.now.timeIntervalSince(delayStart!) / Double(SWITCH_LENGTH_SEC)
                boatImg!.draw(in: boatRect, from: NSZeroRect, operation: NSCompositingOperation.sourceOver, fraction: pctDone)
                
                let oldRect = NSRect(origin: getBoatPos(ind: boatImgIndex-1), size: boatImgs[boatImgIndex-1]!.size)
                
                boatImgs[boatImgIndex-1]!.draw(in: oldRect, from: NSZeroRect, operation: NSCompositingOperation.sourceOver, fraction: 1-pctDone)
            } else {
                boatImg!.draw(in: boatRect)
            }
            
        } else {
            print("Failed to load boat image!")
            NSColor.red.setFill()
//            oceanPath.fill()
        }
    }

    override func animateOneFrame() {
        super.animateOneFrame()
        
        water.animateFrame()
        
        var deadClouds: [Int] = []
        
        for i in 0...clouds.count-1 {
            clouds[i].animate()
            
            if clouds[i].position.x <= -200 {
                deadClouds.append(i)
            }
        }
        
        for dead in deadClouds {
            clouds[dead] = Cloud(pos: randomCloudPos())
        }
        
        for fish in fish {
            fish.animate()
        }
        
        for counter in counters {
            counter.animate()
        }
        
        if fishSpawnEventTimer == nil {
            fishSpawnEventTimer = Date.now
        } else if Date.now.timeIntervalSince(fishSpawnEventTimer!) >= fishSpawnEventInterval && fishToDespawn == nil {
            
            let spawnNew = Bool.random()
            if spawnNew {
                fish.append(Fish(pos: randomFishPos(), parent: self))
            } else {
                fishToDespawn = Int.random(in: 0 ... fish.count - 1)
                fish[fishToDespawn!].beginDespawn()
            }
        } else {
            // Timer is running, check on fishToDespawn
            if fishToDespawn != nil {
                if fish[fishToDespawn!].position.x < -60 || fish[fishToDespawn!].position.x > frame.width + 60 {
                    fish.remove(at: fishToDespawn!)
                    fishToDespawn = nil
                    fishSpawnEventTimer = nil
                    
                    if fish.count < 3 {
                        for _ in 1 ... Int.random(in: 2 ... 5) {
                            fish.append(Fish(pos: randomFishPos(), parent: self))
                        }
                    }
                }
            }
        }
        
        switch phase {
        case .Delay:
            if delayStart == nil {
                delayStart = Date()
            } else {
                if Int(Date.now.timeIntervalSince(delayStart!)) >= DELAY_LENGTH_SEC {
                    phase = .ThrowHook
                }
            }
            break;
        case .ThrowHook:
            if hookPos == nil || hookVel == nil {
                wasUnderwaterLast = false;
                wasUnderwaterBefore = false;
                hookPos = fisherPos()
                hookVel = randomVelocity()
            }
            hookPos!.x += hookVel!.dx
            hookPos!.y += hookVel!.dy
            
            if hookPos!.y < waterLevel && !wasUnderwaterLast {
                // Make water splash
                water.perturb(x: visualHookPos()!.x, intensity: abs(hookVel!.dy))
            }
            
            if hookPos!.y < waterLevel {
                wasUnderwaterLast = true
            } else {
                wasUnderwaterLast = false;
            }
            
            if hookPos!.y > waterLevel {
                hookVel!.dy -= gravity
            } else {
                hookVel!.dy *= 0.97
                hookVel!.dx *= 0.97
            }
            
            if hookPos!.x < 0 || hookPos!.x > frame.width - hookOffset.dx {hookVel!.dx *= -1}
            if hookPos!.y < 0 {hookVel!.dy *= -1}
            if hookPos!.y > frame.height {hookVel!.dy = 0; hookPos!.y = frame.height}
            
            // If hook just hit water
            if hookPos!.y < waterLevel && !wasUnderwaterBefore {
                wasUnderwaterBefore = true
                
                timesUnderwater += 1
                if timesUnderwater == 1 {
                    hookVel!.dy *= -1
                } else {
                    // Slow hook as it hits water
                    hookVel!.dx *= waterDragCoefficient
                    hookVel!.dy = -underwaterSpeed
                }
            }
            break;
        case .ReelIn:
            let hookMoveVec = CGVector(dx: fisherPos().x - hookPos!.x, dy: fisherPos().y - hookPos!.y)
            let magnitude = sqrt(pow(hookMoveVec.dx, 2) + pow(hookMoveVec.dy, 2))
            
            if magnitude < reelBackThreshold {
                var caughtFish: [Int] = []
                for f in 0...fish.count-1 {
                    if fish[f].onHook() {
                        caughtFish.append(f)
                    }
                }
                
                for i in caughtFish {
                    counters[fish[i].getTextureIndex()].increment()
                    
                    let pos = randomFishPos()
                    fish[i] = Fish(pos: pos, parent: self)
                    
                    totalFishCaught += 1
                    if (boatImgIndex == 0 && totalFishCaught >= 10) {
                        boatImgIndex = 1
                        
                        phase = .SwitchShip
                    } else if (boatImgIndex == 1 && totalFishCaught >= 20) {
                        boatImgIndex = 2
                        
                        phase = .SwitchShip
                    } else {
                        phase = .Delay
                    }
                }
                
                if phase == .ReelIn {
                    // If the fish left the hook while reeling in, the code block above did not run, but we still need to switch back to the Delay phase
                    phase = .Delay
                }
                
                resetVars()
            } else {
                let hookMoveVec_norm = CGVector(dx: hookMoveVec.dx / magnitude, dy: hookMoveVec.dy / magnitude)
                let reelInSpeed = 3 * min(1, Date.now.timeIntervalSince(reelInStart) / 2)
                hookPos!.x += hookMoveVec_norm.dx * reelInSpeed
                hookPos!.y += hookMoveVec_norm.dy * reelInSpeed
            }
            break;
        case .SwitchShip:
            if (delayStart == nil) {
                delayStart = Date()
            } else if (Int(Date.now.timeIntervalSince(delayStart!)) >= SWITCH_LENGTH_SEC) {
                phase = .Delay
                resetVars()
            }
            
            break;
        }
        
        setNeedsDisplay(bounds);
    }

    func randomCloudPos() -> CGPoint {
        return CGPoint(x: frame.width + 200, y: CGFloat.random(in: waterLevel * 1.5...frame.height))
    }
    
    func randomFishPos() -> CGPoint {
        return CGPoint(x: Bool.random() ? -50 : frame.width + 50, y: CGFloat.random(in: 0...waterLevel * 0.8))
    }
    
    func nextLowestCounterPos() -> CGFloat {
        var min = CGFloat.infinity
        for counter in counters {
            if counter.position.y < min {min = counter.position.y}
        }
        
        return min - 100
    }
}

class Cloud {
    private var speed: CGFloat = 1
    
    public var position: CGPoint
    private var rects: [NSRect] = []
    
    init(pos: CGPoint) {
        position = pos
        
        for _ in 1...Int.random(in: 5...10) {
            rects.append(NSRect(origin: getRandomOffset(), size: getRandomSize()))
        }
    }
    
    public func draw() {
        NSColor.white.setFill()
        for rect in rects {
            let path = NSBezierPath(ovalIn: NSRect(x: position.x + rect.origin.x, y: position.y + rect.origin.y, width: rect.size.width, height: rect.size.height))
            path.fill()
        }
    }
    
    public func animate() {
        position.x -= speed
    }
    
    func getRandomOffset() -> CGPoint {
        return CGPoint(x: CGFloat.random(in: -50...50), y: CGFloat.random(in: -20...20))
    }
    
    func getRandomSize() -> CGSize {
        return CGSize(width: CGFloat.random(in: 60...200), height: CGFloat.random(in: 10...50))
    }
}

class FishCountView {
    private let parent: GoneFishingView
    private let index: Int
    private var count: Int
    
    var position: CGPoint
    
    private let img: NSImage
    
    private let speed: CGFloat = 1
        
    init(index: Int, pos: CGPoint, parent: GoneFishingView) {
        self.index = index
        self.count = 0
        self.position = pos
        self.parent = parent
        
        // Copies image
        self.img = Fish.fishImgs[index]!.rotatedByDegrees(degrees: 0)
    }
    
    public func increment() {count += 1}
    
    public func draw() {
        let alpha: CGFloat
        if position.y > parent.counterUpperLimit - parent.counterMargin {
            alpha = CGFloat(parent.counterUpperLimit - position.y) / parent.counterMargin
        } else if position.y < parent.counterLowerLimit + parent.counterMargin {
            alpha = CGFloat(position.y - parent.counterLowerLimit) / parent.counterMargin
        } else {alpha = 1}
        
        img.draw(in: NSRect(origin: CGPoint(x: position.x, y: position.y), size: img.size), from: NSZeroRect, operation: NSCompositingOperation.sourceOver, fraction: alpha)
        
        let str = NSString(format: "%d", count)
        str.draw(at: CGPoint(x: position.x + img.size.width + 10, y: position.y + img.size.height / 2 - 10), withAttributes: [NSAttributedString.Key.foregroundColor: NSColor.black.withAlphaComponent(alpha)])
    }
    
    public func animate() {
        position.y += speed
        
        if position.y > parent.counterUpperLimit {
            position.y = parent.nextLowestCounterPos()
        }
    }
}

class Fish {
    private let parent: GoneFishingView
    
    private static let assets = Bundle.init(identifier: "com.ardenkolodner.Gone-Fishing")
    public static let fishImgs: [NSImage?] = [
        assets?.image(forResource: "fish_simple_outlined"),
        assets?.image(forResource: "fish_barrango"),
        assets?.image(forResource: "fish_chromis_viridis"),
        assets?.image(forResource: "fish_clownfish"),
        assets?.image(forResource: "fish_ghost"),
        assets?.image(forResource: "fish_minnow"),
        assets?.image(forResource: "fish_redorange"),
        assets?.image(forResource: "fish_yellowwavy"),
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

// https://stackoverflow.com/questions/31699235/rotate-nsimage-in-swift-cocoa-mac-osx
public extension NSImage {
    func rotateFishByDegrees(degrees: CGFloat, isFlipped: Bool) -> NSImage {
        let img = isFlipped ? self.flippedHorizontally() : self
        let deg = isFlipped ? degrees + 180 : degrees
        
        var imageBounds = NSZeroRect ; imageBounds.size = img.size
        let pathBounds = NSBezierPath(rect: imageBounds)
        var transform = NSAffineTransform()
        transform.rotate(byDegrees: deg)
        pathBounds.transform(using: transform as AffineTransform)
        let rotatedBounds:NSRect = NSMakeRect(NSZeroPoint.x, NSZeroPoint.y, imageBounds.size.width * 2, imageBounds.size.height * 2)
        let rotatedImage = NSImage(size: rotatedBounds.size)
        
        // Position the image within the rotated bounds
//        imageBounds.origin.x = NSMidX(rotatedBounds) - (NSWidth(imageBounds) / 2)
//        imageBounds.origin.y  = NSMidY(rotatedBounds) - (NSHeight(imageBounds) / 2)
        if isFlipped {
            imageBounds.origin.x = NSMidX(rotatedBounds)
            imageBounds.origin.y  = NSMidY(rotatedBounds) / 2
        } else {
            imageBounds.origin.x = 0
            imageBounds.origin.y  = NSMidY(rotatedBounds) / 2
        }
        
        // Start a new transform
        transform = NSAffineTransform()
        // Move coordinate system to the center (since we want to rotate around the center)
        transform.translateX(by: +(NSWidth(rotatedBounds) / 2 ), yBy: +(NSHeight(rotatedBounds) / 2))
        transform.rotate(byDegrees: deg)
        // Move the coordinate system bak to normal
        transform.translateX(by: -(NSWidth(rotatedBounds) / 2 ), yBy: -(NSHeight(rotatedBounds) / 2))
        // Draw the original image, rotated, into the new image
        rotatedImage.lockFocus()
        transform.concat()
        img.draw(in: imageBounds, from: NSZeroRect, operation: NSCompositingOperation.copy, fraction: 1.0)
        rotatedImage.unlockFocus()
        
        return rotatedImage
    }
    
    func rotatedByDegrees(degrees:CGFloat) -> NSImage {
        var imageBounds = NSZeroRect ; imageBounds.size = self.size
        let pathBounds = NSBezierPath(rect: imageBounds)
        var transform = NSAffineTransform()
        transform.rotate(byDegrees: degrees)
        pathBounds.transform(using: transform as AffineTransform)
        let rotatedBounds:NSRect = NSMakeRect(NSZeroPoint.x, NSZeroPoint.y, pathBounds.bounds.size.width, pathBounds.bounds.size.height )
        let rotatedImage = NSImage(size: rotatedBounds.size)
        
        //Center the image within the rotated bounds
        imageBounds.origin.x = NSMidX(rotatedBounds) - (NSWidth(imageBounds) / 2)
        imageBounds.origin.y  = NSMidY(rotatedBounds) - (NSHeight(imageBounds) / 2)
        
        // Start a new transform
        transform = NSAffineTransform()
        // Move coordinate system to the center (since we want to rotate around the center)
        transform.translateX(by: +(NSWidth(rotatedBounds) / 2 ), yBy: +(NSHeight(rotatedBounds) / 2))
        transform.rotate(byDegrees: degrees)
        // Move the coordinate system bak to normal
        transform.translateX(by: -(NSWidth(rotatedBounds) / 2 ), yBy: -(NSHeight(rotatedBounds) / 2))
        // Draw the original image, rotated, into the new image
        rotatedImage.lockFocus()
        transform.concat()
        self.draw(in: imageBounds, from: NSZeroRect, operation: NSCompositingOperation.copy, fraction: 1.0)
        rotatedImage.unlockFocus()
        
        return rotatedImage
    }
    
    func flippedHorizontally() -> NSImage {
        var imageBounds = NSZeroRect ; imageBounds.size = self.size
        let pathBounds = NSBezierPath(rect: imageBounds)
        var transform = NSAffineTransform()
        transform.scaleX(by: -1, yBy: 1)
        pathBounds.transform(using: transform as AffineTransform)
        let rotatedBounds:NSRect = NSMakeRect(NSZeroPoint.x, NSZeroPoint.y, pathBounds.bounds.size.width, pathBounds.bounds.size.height )
        let rotatedImage = NSImage(size: rotatedBounds.size)
        
        //Center the image within the rotated bounds
        imageBounds.origin.x = NSMidX(rotatedBounds) - (NSWidth(imageBounds) / 2)
        imageBounds.origin.y  = NSMidY(rotatedBounds) - (NSHeight(imageBounds) / 2)
        
        // Start a new transform
        transform = NSAffineTransform()
        // Move coordinate system to the center (since we want to rotate around the center)
        transform.translateX(by: +(NSWidth(rotatedBounds) / 2 ), yBy: +(NSHeight(rotatedBounds) / 2))
        transform.scaleX(by: -1, yBy: 1)
        // Move the coordinate system bak to normal
        transform.translateX(by: -(NSWidth(rotatedBounds) / 2 ), yBy: -(NSHeight(rotatedBounds) / 2))
        // Draw the original image, rotated, into the new image
        rotatedImage.lockFocus()
        transform.concat()
        self.draw(in: imageBounds, from: NSZeroRect, operation: NSCompositingOperation.copy, fraction: 1.0)
        rotatedImage.unlockFocus()
        
        return rotatedImage
    }
    
    func flippedVertically() -> NSImage {
        var imageBounds = NSZeroRect ; imageBounds.size = self.size
        let pathBounds = NSBezierPath(rect: imageBounds)
        var transform = NSAffineTransform()
        transform.scaleX(by: 1, yBy: -1)
        pathBounds.transform(using: transform as AffineTransform)
        let rotatedBounds:NSRect = NSMakeRect(NSZeroPoint.x, NSZeroPoint.y, pathBounds.bounds.size.width, pathBounds.bounds.size.height )
        let rotatedImage = NSImage(size: rotatedBounds.size)
        
        //Center the image within the rotated bounds
        imageBounds.origin.x = NSMidX(rotatedBounds) - (NSWidth(imageBounds) / 2)
        imageBounds.origin.y  = NSMidY(rotatedBounds) - (NSHeight(imageBounds) / 2)
        
        // Start a new transform
        transform = NSAffineTransform()
        // Move coordinate system to the center (since we want to rotate around the center)
        transform.translateX(by: +(NSWidth(rotatedBounds) / 2 ), yBy: +(NSHeight(rotatedBounds) / 2))
        transform.scaleX(by: -1, yBy: 1)
        // Move the coordinate system bak to normal
        transform.translateX(by: -(NSWidth(rotatedBounds) / 2 ), yBy: -(NSHeight(rotatedBounds) / 2))
        // Draw the original image, rotated, into the new image
        rotatedImage.lockFocus()
        transform.concat()
        self.draw(in: imageBounds, from: NSZeroRect, operation: NSCompositingOperation.copy, fraction: 1.0)
        rotatedImage.unlockFocus()
        
        return rotatedImage
    }
}
