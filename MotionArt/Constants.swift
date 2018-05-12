//
//  Constants.swift
//  MotionArt
//
//  Created by Lucy Zhang on 3/19/18.
//  Copyright © 2018 Lucy Zhang. All rights reserved.
//

import Foundation

struct Constants{
    // Collision bounds
    static let BOUNDS:Float = 0.2
    
    // For collision - how much the node moves back on collision
    static let INCREMENT:Float = 0.07
    static let NUM_NODES:Int = 32
    static let FRAME_COUNT:Int = Constants.NUM_NODES * 2
    
    static let NUM_RINGS:Int = 5
    static let RING_SEPARATION:Float = 0.4
    static let BOX_DIMENSIONS:Float = 0.2
    static let RADIUS:Float = 1
}
