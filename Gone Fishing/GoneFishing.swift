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
        
    private var droplets: [Droplet]
    private let splashVarianceXLower: CGFloat = -1.0
    private let splashVarianceXUpper: CGFloat = 2.0
    private let splashVarianceYLower: CGFloat = 0.5
    private let splashVarianceYUpper: CGFloat = 1.0
    
    private let water: SimulatedWater
    
    private var fish: [Fish]
    private var fishToDespawn: Int?
    private var fishSpawnEventTimer: Date?
    private let fishSpawnEventInterval: CGFloat = 10
    
    private var weatherChangePrevious = Date.now
    private let weatherChangeEventInterval: CGFloat = 10
    
    private var lightningPrevious = Date.now
    private let lightningInterval: CGFloat = 2
    
    public var counterUpperLimit: CGFloat = 1000
    public var counterLowerLimit: CGFloat = 400
    public var counterMargin: CGFloat = 200
    
    private var counters: [FishCountView]
    
    private var totalFishCaught = 0
    
    private let skyColor = NSColor(red: 0.52, green: 0.81, blue: 0.92, alpha: 1)
    private let oceanColor = NSColor(red: 0.03, green: 0.23, blue: 0.81, alpha: 1)
    
    private var skyGradient: NSGradient
    private var gradientColor: NSColor
    private let skyGradientFraction = 0.2 // Fraction of WHOLE SCREEN that is the sky gradient. Rest has sky color drawn flat. The performance hit is way too big to draw the gradient across the whole screen.
    private let skyGradientBlackFrac = 0.3 // This much black is blended with the sky color at the top of the screen
    private let flatRect: NSRect
    private let gradientRect: NSRect
    
    private let splashDropSize: CGFloat = 5
    private let rainDropSize: CGFloat = 4
        
    public func getFrame() -> NSRect {return frame}
    
    public func getPhase() -> Phase {return phase}
    
    // MARK: - Initialization
    override init?(frame: NSRect, isPreview: Bool) {
        counterUpperLimit = 5 * frame.height / 6
        counterLowerLimit = frame.height / 6
        counterMargin = frame.height / 5
        
        boatImgs = [
            MediaLoader.loadImage("sailboat"),
            MediaLoader.loadImage("galleon"),
            MediaLoader.loadImage("galleon_insignia"),
        ]
        hookImg = MediaLoader.loadImage("fishhook")
        
        phase = Phase.Delay
        delayStart = nil
        
        waterLevel = frame.height / 2
        
        clouds = []
        
        fish = []
        
        counters = []
        
        droplets = []
        
        water = SimulatedWater(frame: frame, waterLevel: waterLevel, waterColor: oceanColor)
        
        let startingWeatherRoll = Int.random(in: 1...3)
        WeatherManager.setStartingWeather(start: startingWeatherRoll == 1 ? .Clear : startingWeatherRoll == 2 ? .Rainy : .Stormy)
        
        skyGradient = NSGradient(
            starting: skyColor,
            ending: skyColor.blended(withFraction: skyGradientBlackFrac, of: NSColor.black)!
        )!
        gradientColor = skyColor
        flatRect = NSRect(x: 0, y: 0, width: frame.width,
                          height: frame.height * (1-skyGradientFraction))
        gradientRect = NSRect(x: 0, y: flatRect.height, width: frame.width,
                                  height: frame.height * skyGradientFraction)
    
        super.init(frame: frame, isPreview: isPreview)
        
        var yPos = 600
        for i in 0 ... Fish.fishImgs.count-1 {
            counters.append(FishCountView(index: i, pos: CGPoint(x: 50, y: yPos), parent: self))
            yPos -= 100
        }
        
        let numClouds = Int.random(in: 7...12)
        for i in 1...numClouds {
            let c = Cloud(pos: randomCloudPos(), depth: CGFloat.random(in: 0...1))
            c.position.x = frame.width * CGFloat(i) / CGFloat(numClouds)
            clouds.append(c)
            sortClouds()
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
    
    private func sortClouds() {
        clouds.sort {
            return $0.getDepth() < $1.getDepth()
        }
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
        return CGPoint(
            x: water.getPtPos(index: 10).x + boatOffsets[boatImgIndex].x,
            y: water.getPtPos(index: 10).y + boatOffsets[boatImgIndex].y
        )
    }
    
    func getBoatPos(ind: Int) -> CGPoint {
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
        
        let color = NSColor.black.blended(withFraction: WeatherManager.getCloudShadeMultiplier(), of: skyColor)!
        if color != gradientColor {
            gradientColor = color
            skyGradient = NSGradient(
                starting: color,
                ending: color.blended(withFraction: skyGradientBlackFrac, of: NSColor.black)!
            )!
        }
        
        color.drawSwatch(in: flatRect)
        skyGradient.draw(in: gradientRect, angle: 90)
        
        water.draw()
        
        for droplet in droplets {droplet.draw()}
        
        for cloud in clouds {cloud.draw()}
        
        for f in fish {f.draw()}
        
        for c in counters {c.draw()}
        
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
        
        WeatherManager.animate()
        
        water.animateFrame()
        
        var deadClouds: [Int] = []
        
        for i in 0...clouds.count-1 {
            clouds[i].animate()
            
            if clouds[i].position.x <= -200 {
                deadClouds.append(i)
            }
        }
        
        for dead in deadClouds {
            clouds[dead] = Cloud(pos: randomCloudPos(), depth: CGFloat.random(in: 0...1))
            sortClouds()
        }
        
        // If it's raining (including storming)
        if [Weather.Rainy, Weather.Stormy].contains(WeatherManager.getWeather()) {
            for cloud in clouds {
                if cloud.shouldDoRain() {
                    droplets.append(Droplet(
                        position: cloud.getRainPos(),
                        velocity: CGVector.zero,
                        color: oceanColor,
                        size: rainDropSize
                    ))
                }
            }
        }
        
        if WeatherManager.getWeather() == .Stormy {
            if Date.now.timeIntervalSince(lightningPrevious) >= lightningInterval {
                lightningPrevious = Date.now
                
                let c = clouds.randomElement()!
                let waterHeight = water.getWaterLevelAt(pos: c.getPos())
                
                c.doLightning(waterHeight: waterHeight)
                water.perturb(x: c.getPos().x, intensity: -40)
            }
        }
        
        if droplets.count > 0 {
            var livingDroplets: [Droplet] = []
            for i in 0...droplets.count-1 {
                droplets[i].animate()
                let p = droplets[i].getPos()
                if !(p.x > frame.width || p.x < 0 || p.y < water.getWaterLevelAt(pos: droplets[i].getPos())) {
                    // If droplet is still in bounds, copy it to the list of living droplets. Otherwise, it will be deleted.
                    livingDroplets.append(droplets[i])
                } else if p.x > 0 && p.x < frame.width {
                    // If droplet went out of bounds by hitting the water (still in the right X range), perturb the water's surface
                    water.perturb(x: p.x, intensity: 2)
                }
            }
            droplets = livingDroplets
        }
        
        for fish in fish {
            fish.animate()
        }
        
        for counter in counters {
            counter.animate()
        }
                
        if Date.now.timeIntervalSince(weatherChangePrevious) >= weatherChangeEventInterval {
            weatherChangePrevious = Date.now
            
            let startingWeatherRoll = Int.random(in: 1...3)
            WeatherManager.startTransitionTo(weather: startingWeatherRoll == 1 ? .Clear : startingWeatherRoll == 2 ? .Rainy : .Stormy)
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
            
            if hookPos!.y < water.getWaterLevelAt(x: hookPos!.x) && !wasUnderwaterLast {
                // Make water splash
                water.perturb(x: visualHookPos()!.x, intensity: abs(hookVel!.dy))
                
                for _ in 1...Int.random(in: 7...15) {
                    droplets.append(
                        Droplet(
                            position: visualHookPos()!,
                            velocity: randomDropletVel(),
                            color: oceanColor,
                            size: splashDropSize
                        )
                    )
                }
            }
            
            if hookPos!.y < water.getWaterLevelAt(x: hookPos!.x) {
                wasUnderwaterLast = true
            } else {
                wasUnderwaterLast = false;
            }
            
            if hookPos!.y > water.getWaterLevelAt(x: hookPos!.x) {
                hookVel!.dy -= gravity
            } else {
                hookVel!.dy *= 0.97
                hookVel!.dx *= 0.97
            }
            
            if hookPos!.x < 0 || hookPos!.x > frame.width - hookOffset.dx {hookVel!.dx *= -1}
            if hookPos!.y < 0 {hookVel!.dy *= -1}
            if hookPos!.y > frame.height {hookVel!.dy = 0; hookPos!.y = frame.height}
            
            // If hook just hit water
            if hookPos!.y < water.getWaterLevelAt(x: hookPos!.x) && !wasUnderwaterBefore {
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
    
    func randomDropletVel() -> CGVector {
        return CGVector(
            dx: hookVel!.dx * CGFloat.random(in: splashVarianceXLower...splashVarianceXUpper),
            dy: abs(hookVel!.dy) * CGFloat.random(in: splashVarianceYLower...splashVarianceYUpper)
        )
    }
}
