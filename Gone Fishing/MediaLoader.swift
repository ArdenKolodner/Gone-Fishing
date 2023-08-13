//
//  MediaLoader.swift
//  Gone Fishing
//
//  Created by Arden Kolodner on 8/12/23.
//

import ScreenSaver

/*
 * This singleton class loads image files from asset bundles.
 * Since this is a slightly different process in the screensaver vs. in testing, this allows for one
 * easy call that handles both cases.
 */
class MediaLoader {
    // Screensaver assets
    private static let assets = Bundle.init(identifier: "com.ardenkolodner.Gone-Fishing")
    // Testing assets
    private static let main = Bundle.main
    
    public static func loadImage(_ path: String) -> NSImage? {
        let i = assets?.image(forResource: path)
        if i != nil {return i!}
        return main.image(forResource: path)
    }
}
