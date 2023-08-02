//
//  SimulatedWater.swift
//  Gone Fishing
//
//  Created by Arden Kolodner on 8/2/23.
//

import ScreenSaver
import Foundation

class SimulatedWater {
    private let frame: NSRect
    
    private let waterLevel: CGFloat
    
    private var waterColor: NSColor
    
    private let pxPerPt: CGFloat = 20
    private let numPts: Int
    
    private let returnForceCoeff: CGFloat = 0.001
    private let accelSpeed = 0.03
    private let dampeningCoeff = 0.95
                
    private var waterXPts: [CGFloat]
    private var waterYPts: [CGFloat]
    
    private var waterSpeeds: [CGFloat]
    
    init(frame: NSRect, waterLevel: CGFloat, waterColor: NSColor) {
        self.frame = frame
        self.waterLevel = waterLevel
        self.waterColor = waterColor
        
        self.numPts = Int(frame.width / pxPerPt) + 1
        
        self.waterXPts = []
        for i in 0...numPts-1 {
            self.waterXPts.append(CGFloat(i) * pxPerPt)
        }
        self.waterXPts.append(frame.width)
        
        self.waterYPts = []
        for _ in 0...numPts {
            self.waterYPts.append(waterLevel)
        }
        
        self.waterSpeeds = []
        for _ in 0...numPts {
            self.waterSpeeds.append(0)
        }
    }
    
    public func animateFrame() {
        for i in 0...numPts {
            let dispFromLeft, dispFromRight: CGFloat
            if i == 0 {dispFromLeft = 0}
            else {
                dispFromLeft = waterYPts[i-1] - waterYPts[i]
            }
            if i == numPts {dispFromRight = 0}
            else {
                dispFromRight = waterYPts[i+1] - waterYPts[i]
            }
            
            let returnForce = (waterLevel - waterYPts[i]) * returnForceCoeff
            let netDisp = dispFromLeft + dispFromRight + returnForce
            
            let accel = netDisp * accelSpeed
            waterSpeeds[i] += accel
        }
        
        for i in 0...numPts {
            waterYPts[i] += waterSpeeds[i]
            waterSpeeds[i] *= dampeningCoeff
        }
    }
    
    public func draw() {
        let path = NSBezierPath()
        path.move(to: NSPoint(x: waterXPts[0], y: waterYPts[0]))
        
        for i in 1...numPts {
            path.line(to: NSPoint(x: waterXPts[i], y: waterYPts[i]))
        }
        
        path.line(to: NSPoint(x: frame.width, y: 0))
        path.line(to: NSPoint.zero)
        
        path.close()
        
        waterColor.setFill()
        
        path.fill()
    }
    
    public func perturb(x: CGFloat, intensity: CGFloat) {
        let closestPt = Int(round(x / pxPerPt))
        
        waterSpeeds[closestPt] -= intensity
    }
}
