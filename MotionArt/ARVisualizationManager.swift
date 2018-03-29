//
//  ARVisualizationManager.swift
//  MotionArt
//
//  Created by Lucy Zhang on 3/29/18.
//  Copyright © 2018 Lucy Zhang. All rights reserved.
//

import UIKit

protocol ARVisualizationManagerDelegate{
    func onSettingChange()
}

class ARVisualizationManager: NSObject {
    
    static let shared = ARVisualizationManager()
    
    var visualizations:[ARVisualization] = [ARVisualization(name: "Motion"), ARVisualization(name: "Anime")]
    
    var delegate:ARVisualizationManagerDelegate?
    
    var needsRefresh:Bool = false
    
    func addSetting(setting:ARVisualization){
        self.visualizations.append(setting)
        
        if self.delegate == nil{
            needsRefresh = true
        }
        self.delegate?.onSettingChange()
    }

}
