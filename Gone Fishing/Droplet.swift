//
//  Droplet.swift
//  Gone Fishing
//
//  Created by Arden Kolodner on 8/3/23.
//

import ScreenSaver

class Droplet {
    private var position: CGPoint
    private var velocity: CGVector
    
    private let size: CGFloat = 5
    
    private let gravity: CGFloat = 1
    
    private var color: NSColor
    
    init(position: CGPoint, velocity: CGVector, color: NSColor) {
        self.position = position
        self.velocity = velocity
        self.color = color
    }
    
    public func animate() {
        position.x += velocity.dx
        position.y += velocity.dy
        
        velocity.dy -= gravity
    }
    
    public func draw() {
        let r = NSRect(x: position.x - size/2, y: position.y - size/2, width: size, height: size)
        let p = NSBezierPath(ovalIn: r)
        
        color.setFill()
        p.fill()
    }
    
    public func getPos() -> CGPoint {return position}
}
