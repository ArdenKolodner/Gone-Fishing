//
//  SimulatedWater.swift
//  Gone Fishing
//
//  Created by Arden Kolodner on 8/2/23.
//

import ScreenSaver
import Foundation

/*
 * The water is modeled as a series of control points, each with velocity,
 * that are attached via vertical springs to each neighbor.
 * There are 3 forces: acceleration towards neighbors, damping, and return to initial height.
 */
class SimulatedWater {
    private let frame: NSRect // Reference to canvas
    
    // Initial water height, and where water tries to go back to in the absense of other forces
    private let waterLevel: CGFloat // Passed as a parameter
    
    // Color of water (before taking into account water and bottom gradient)
    private var waterColor: NSColor
    
    // How many pixels between each control point of the water
    private let pxPerPt: CGFloat = 20
    // Number of control points in the water.
    // There are actually this many plus one, so that far left is 0 and far right is numPts
    private let numPts: Int
    
    // Strength of force pushing water back to its initial height (waterLevel)
    private let returnForceCoeff: CGFloat = 1
    // Strength of force pulling each point towards its neighbors
    private let accelSpeed = 0.05
    // Damping coefficient on each control point's motion
    private let dampeningCoeff = 0.95
    
    // Coordinates of each control point. Kept in parallel, entries from 0 to numPts inclusive.
    private var waterXPts: [CGFloat]
    private var waterYPts: [CGFloat]
    
    // Velocity of each control point
    private var waterSpeeds: [CGFloat]
    
    // Gradient to fill bottom of ocean is kept pre-generated when possible
    private var waterGradient: NSGradient
    // Color that was used to generate the gradient
    // Also serves as a check of whether to re-generate it
    private var gradientColor: NSColor
    
    // This fraction of the screen is drawn by the gradient, the rest is flat
    private let flatColorFrac = 0.2
    // Gradient is only drawn in bottom part of the screen, and it's assumed that the water
    // surface never reaches that low, so we can keep the rect pre-generated
    private let gradientRect: NSRect
    // This much black is blended with the water color at the bottom of the screen
    private let gradientBlackFrac = 0.4
    
    init(frame: NSRect, waterLevel: CGFloat, waterColor: NSColor) {
        self.frame = frame
        self.waterLevel = waterLevel
        self.waterColor = waterColor
        
        // Calculate how many control points can fit across the screen
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
        var closestPt = Int(round(x / pxPerPt))
        if closestPt < 0 {closestPt = 0}
        else if closestPt > numPts {closestPt = numPts}
        
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
