//
//  WeatherManager.swift
//  Gone Fishing
//
//  Created by Arden Kolodner on 8/3/23.
//

import ScreenSaver

enum Weather {
    case None
    case Clear
    case Rainy
    case Stormy
    case Transition
}

let weatherCloudShades: [Weather:CGFloat] = [
    .None: CGFloat.nan, // Should not be used
    .Transition: CGFloat.nan, // Should not be used, should be calculated by linear interpolation between transitionPrevious and transitionTarget
    
    .Clear: 1.0,
    .Rainy: 0.8,
    .Stormy: 0.5,
]

class WeatherManager {
    private static var currentWeather = Weather.None
    
    private static var transitionPrevious = Weather.None
    private static var transitionTarget = Weather.None
    
    private static var transitionTimeStart: Date?
    private static let weatherTransitionTime: CGFloat = 5 // in seconds
    
    @available(*, unavailable) private init() {}
    
    public static func getWeather() -> Weather {return currentWeather}
    
    // Should only be called once, at startup
    public static func setStartingWeather(start: Weather) {
        currentWeather = start
    }
    
    public static func startTransitionTo(weather: Weather) {
        transitionPrevious = currentWeather
        transitionTarget = weather
        
        currentWeather = .Transition
        
        transitionTimeStart = Date.now
    }
    
    public static func getCloudShadeMultiplier() -> CGFloat {
        switch currentWeather {
        case .None: fallthrough
        case .Clear: fallthrough
        case .Rainy: fallthrough
        case .Stormy:
            return weatherCloudShades[currentWeather]!
        case .Transition:
            let transitionProgress = Date.now.timeIntervalSince(transitionTimeStart!) / weatherTransitionTime
            return weatherCloudShades[transitionTarget]! * transitionProgress + weatherCloudShades[transitionPrevious]! * (1-transitionProgress)
        }
    }
    
    public static func animate() {
        if transitionTimeStart != nil {
            let transitionProgress = Date.now.timeIntervalSince(transitionTimeStart!) / weatherTransitionTime
            if transitionProgress >= 1 {
                currentWeather = transitionTarget
                transitionTimeStart = nil
            }
        }
    }
}
