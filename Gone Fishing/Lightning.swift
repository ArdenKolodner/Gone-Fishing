//
//  Lightning.swift
//  Gone Fishing
//
//  Created by Arden Kolodner on 8/12/23.
//
//  Lightning algorithm is adapted from https://web.archive.org/web/20190816102613/http://drilian.com/2009/02/25/lightning-bolts/

import ScreenSaver
import Foundation

// Lightning is generated inside a 300-by-300 square, origin in top left, should be changed to fit target size
// All points are relative to this, not the global frame
class Lightning {
//    private let height: CGFloat
//    private let width: CGFloat
    
    private let subdivisionPasses = 6
    private let initialOffset: CGFloat = 250
    private let initialIntensity = 1.0
    
    private var lines: [Segment]
    
    struct Segment {
        var p1: NSPoint
        var p2: NSPoint
        var intensity: CGFloat
    }
    
    private let origin: NSPoint
    private let target: NSPoint
    
    private var offsetAmount: CGFloat
    
    init(origin: NSPoint, target: NSPoint) {
        // ------ Initialize ------
//        self.height = height
//        self.width = width
        
//        self.origin = NSPoint(x: width/2, y: 0)
//        self.target = NSPoint(x: width/2, y: height)
        self.origin = origin
        self.target = target
        
        self.offsetAmount = initialOffset
        
        // ------ Generate ------
        self.lines = [
            Segment(p1: origin, p2: target, intensity: initialIntensity)
        ]
        
        for _ in 1...subdivisionPasses {
            var newLines: [Segment] = []
            
            for line in lines {
                let midpoint = perturbedMid(line.p1, line.p2)
                
                newLines.append(Segment(p1: line.p1, p2: midpoint, intensity: line.intensity))
                newLines.append(Segment(p1: midpoint, p2: line.p2, intensity: line.intensity))
                
                if Int.random(in: 1...4) == 1 {
                    let extended = extend(line.p1, midpoint, line.intensity)
                    newLines.append(extended)
                }
            } // for line in lines
            
            lines = newLines
            self.offsetAmount /= 2
        } // subdivisionPasses
        
        // Sort lines so highest intensity lines are on top
        lines.sort {
            return $0.intensity > $1.intensity
        }
    } // init
    
    public func draw() {
        for line in lines {
            let path = NSBezierPath()
            path.move(to: line.p1)
            path.line(to: line.p2)
            path.lineWidth = 2
            
            NSColor.white.blended(
                withFraction: line.intensity,
                of: NSColor.black
            )!.setStroke()
            path.stroke()
        }
    }
    
    private func calcMidpoint(_ p1: NSPoint, _ p2: NSPoint) -> NSPoint {
        return NSPoint(
            x: (p1.x+p2.x)/2,
            y: (p1.y+p2.y)/2
        )
    }
    
    private func calcNormal(_ p1: NSPoint, _ p2: NSPoint) -> NSPoint {
        return NSPoint(
            x: -(p2.y - p1.y),
            y: p2.x - p1.x
        )
    }
    
    private func normalize(_ v: NSPoint) -> NSPoint {
        let magnitude = sqrt(pow(v.x, 2) + pow(v.y, 2)) // Pythagorean theorem
        return NSPoint(x: v.x / magnitude, y: v.y / magnitude)
    }
    
    private func extend(_ p1: NSPoint, _ p2: NSPoint, _ previousIntensity: CGFloat) -> Segment {
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        return Segment(
            p1: p1,
           p2: NSPoint(
            x: p1.x + 2*dx,
            y: p1.y + 2*dy
           ),
           intensity: previousIntensity / 2
        )
    }
    
    private func perturbedMid(_ p1: NSPoint, _ p2: NSPoint) -> NSPoint {
        let mid = self.calcMidpoint(p1, p2)
        let normal = self.normalize(self.calcNormal(p1, p2))
        let frac = CGFloat.random(in: 0...1) * self.offsetAmount - self.offsetAmount/2
        
        return NSPoint(
            x: mid.x + normal.x * frac,
            y: mid.y + normal.y * frac
        )
    }
}
