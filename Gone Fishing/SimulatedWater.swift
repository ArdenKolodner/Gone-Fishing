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
    
    private let returnForceCoeff: CGFloat = 1
    private let accelSpeed = 0.05
    private let dampeningCoeff = 0.95
                
    private var waterXPts: [CGFloat]
    private var waterYPts: [CGFloat]
    
    private var waterSpeeds: [CGFloat]
    
    private var waterGradient: NSGradient
    private var gradientColor: NSColor
    
    private let flatColorFrac = 0.2 // This fraction of the screen is drawn by the gradient, the rest is flat
    private let gradientRect: NSRect
    private let gradientBlackFrac = 0.4 // This much black is blended with the water color at the bottom of the screen
    
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
        
        self.waterGradient = NSGradient(
            starting: waterColor,
            ending: waterColor.blended(withFraction: gradientBlackFrac, of: NSColor.black)!
        )!
        self.gradientColor = waterColor
        
        self.gradientRect = NSRect(x: 0, y: 0, width: frame.width,
                                   height: frame.height * flatColorFrac)
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
            waterSpeeds[i] += accel + randomSmallAccel()
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
            let pt1 = NSPoint(
                x: waterXPts[i-1] * 0.75 + waterXPts[i] * 0.25,
                y: waterYPts[i-1])
            let pt2 = NSPoint(
                x: waterXPts[i-1] * 0.25 + waterXPts[i] * 0.75,
                y: waterYPts[i])
            
            path.curve(to: NSPoint(x: waterXPts[i], y: waterYPts[i]), controlPoint1: pt1, controlPoint2: pt2)
        }
        
        path.line(to: NSPoint(x: frame.width, y: gradientRect.height))
        path.line(to: NSPoint(x: 0, y: gradientRect.height))
        
        path.close()
        
        // Water color is shaded based on weather
        let color = NSColor.black.blended(withFraction: WeatherManager.getOceanShadeMultiplier(), of: waterColor)!
        
        if color != self.gradientColor {
            self.gradientColor = color
            self.waterGradient = NSGradient(
                starting: color,
                ending: waterColor.blended(withFraction: gradientBlackFrac, of: NSColor.black)!
            )!
        }
        
        color.setFill()
        path.fill()
        
        self.waterGradient.draw(in: gradientRect, angle: -90)
    }
    
    public func perturb(x: CGFloat, intensity: CGFloat) {
        let closestPt = Int(round(x / pxPerPt))
        
        waterSpeeds[closestPt] -= intensity
    }
    
    public func getPtPos(index: Int) -> CGPoint {
        return CGPoint(x: waterXPts[index], y: waterYPts[index])
    }
    
    public func getWaterLevelAt(x: CGFloat) -> CGFloat {
        var closestPt = Int(round(x / pxPerPt))
        if closestPt < 0 {closestPt = 0}
        if closestPt > numPts {closestPt = numPts}
        
        return waterYPts[closestPt]
    }
    
    public func getWaterLevelAt(pos: CGPoint) -> CGFloat {
        return getWaterLevelAt(x: pos.x)
    }
    
    private func randomSmallAccel() -> CGFloat {
        return CGFloat.random(in: -0.2...0.2)
    }
}
