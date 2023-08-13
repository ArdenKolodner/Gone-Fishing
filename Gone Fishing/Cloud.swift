//
//  Cloud.swift
//  Gone Fishing
//
//  Created by Arden Kolodner on 8/3/23.
//

import ScreenSaver

class Cloud {
    private var speed: CGFloat = 1
    
    private let depth: CGFloat
    private let color: NSColor
    private let minColor = 0.7
    
    public var position: CGPoint
    private var rects: [NSRect] = []
    
    private var lastRainTime = Date.now
    private let rainInterval_rainy: CGFloat = 0.1
    private let rainInterval_stormy: CGFloat = 0.06
    
    private var lightning: Lightning? = nil // Optional type because creating a lightning bolt is expensive, and we want to avoid that
    private var lightningBeginTime = Date.now
    private let lightningDuration: CGFloat = 0.3
    
    init(pos: CGPoint, depth: CGFloat) {
        self.position = pos
        self.depth = depth
        self.color = NSColor(
            white: depth * (1 - minColor) + minColor,
            alpha: 1
        )
        
        for _ in 1...Int.random(in: 5...10) {
            rects.append(NSRect(origin: getRandomOffset(), size: getRandomSize()))
        }
    }
    
    public func draw() {
        getColor().setFill()
        for rect in rects {
            let path = NSBezierPath(ovalIn: NSRect(x: position.x + rect.origin.x, y: position.y + rect.origin.y, width: rect.size.width, height: rect.size.height))
            path.fill()
        }
        
        lightning?.draw()
    }
    
    public func animate() {
        position.x -= speed
        
        if lightning != nil && Date.now.timeIntervalSince(lightningBeginTime) > lightningDuration {
            lightning = nil
        }
    }
    
    /*
     * Returns the (principal) position that the lightning impacted at
     */
    public func doLightning(waterHeight: CGFloat) -> CGPoint {
        var target = getRainPos()
        target = CGPoint(x: target.x, y: waterHeight)
        lightning = Lightning(origin: getRainPos(), target: target)
        
        lightningBeginTime = Date.now
        
        return target
    }
    
    public func shouldDoRain() -> Bool {
        if Date.now.timeIntervalSince(lastRainTime) > getRainInterval() {
            lastRainTime = Date.now
            return true
        }
        return false
    }
    
    public func getDepth() -> CGFloat {return depth}
    public func getPos() -> CGPoint {return position}
    
    func getRandomOffset() -> CGPoint {
        return CGPoint(x: CGFloat.random(in: -50...50), y: CGFloat.random(in: -20...20))
    }
    
    func getRandomSize() -> CGSize {
        return CGSize(width: CGFloat.random(in: 60...200), height: CGFloat.random(in: 10...50))
    }
    
    public func getRainPos() -> CGPoint {
        let r = rects.randomElement()!
        let o = r.origin
        let offset = r.size.width * CGFloat.random(in: 0...1)
        
        return CGPoint(x: o.x + position.x + offset, y: o.y + position.y)
    }
    
    private func getColor() -> NSColor {
        // Darken cloud's color by a percent determined by the weather
        // For intuivitity, the fraction returned is the fractional brightness, so we could either blend the color by 1-frac of black,
        // or blend black by (frac) of the color, all of which result in shading the color by (1-frac) of black
        return NSColor.black.blended(withFraction: WeatherManager.getCloudShadeMultiplier(), of: color)!
    }
    
    private func getRainInterval() -> CGFloat {
        switch WeatherManager.getWeather() {
        case .Rainy: return rainInterval_rainy
        case .Stormy: return rainInterval_stormy
        default: return CGFloat.nan
        }
    }
}
