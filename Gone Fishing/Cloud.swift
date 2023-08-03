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
        color.setFill()
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
    
    private static func randomCloudColor() -> NSColor {
        return NSColor(white: CGFloat.random(in: 0.8...1), alpha: 1)
    }
}
