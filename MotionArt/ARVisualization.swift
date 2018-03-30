//
//  ARVisualization.swift
//  MotionArt
//
//  Created by Lucy Zhang on 3/29/18.
//  Copyright © 2018 Lucy Zhang. All rights reserved.
//

import UIKit

class ARVisualization: NSObject {
    var name:String!
    
    var bounds:Float = Constants.BOUNDS
    var increment:Float = Constants.INCREMENT
    var num_nodes:Int = Constants.NUM_NODES
    lazy var frame_count:Int = {
        return self.num_nodes * 2
    }()
    
    var num_rings:Int = Constants.NUM_RINGS
    var ring_separation:Float = Constants.RING_SEPARATION
    var box_dimensions:Float = Constants.BOX_DIMENSIONS
    
    var musicAssetURL:URL!
    
    lazy var settings:[String:Any] = {
        return ["bounds":self.bounds, "increment":self.increment, "num_nodes":self.num_nodes, "frame_count":frame_count, "num_rings":self.num_rings, "ring_separation":self.ring_separation, "box_dimensions":self.box_dimensions, "musicAssetURL":self.musicAssetURL]
    }()
    
//    init() {
//    }

    convenience init(name:String) {
        self.init()
        self.name = name
    }

}
