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
    private let height: CGFloat
    private let width: CGFloat
    
    private let subdivisionPasses = 6
    private let initialOffset = 250
    private let initialIntensity = 1.0
    
    struct Segment {
        var p1: NSPoint
        var p2: NSPoint
        var intensity: CGFloat
    }
    
    private let origin: NSPoint
    private let target: NSPoint
    
    init(width: CGFloat, height: CGFloat) {
        self.height = height
        self.width = width
        
        self.origin = NSPoint(x: width/2, y: 0)
        self.target = NSPoint(x: width/2, y: height)
        
        
    }
}
