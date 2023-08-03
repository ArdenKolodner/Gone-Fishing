//
//  FishCountView.swift
//  Gone Fishing
//
//  Created by Arden Kolodner on 8/3/23.
//

import ScreenSaver

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
