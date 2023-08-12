//
//  MediaLoader.swift
//  Gone Fishing
//
//  Created by Arden Kolodner on 8/12/23.
//

import ScreenSaver

class MediaLoader {
    private static let main = Bundle.main
    private static let assets = Bundle.init(identifier: "com.ardenkolodner.Gone-Fishing")
    
    public static func loadImage(_ path: String) -> NSImage? {
        let i = assets?.image(forResource: path)
        if i != nil {return i!}
        return main.image(forResource: path)
    }
}
