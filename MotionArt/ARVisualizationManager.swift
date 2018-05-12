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
    
    var visualizations:[ARVisualization] = [ARVisualization(name: "Motion"), ARVisualization(name: "Anime")] {
        didSet{
            self.delegate?.onSettingChange()
        }
    }
    
    var delegate:ARVisualizationManagerDelegate?
    
    var needsRefresh:Bool = false
    
    func addSetting(setting:ARVisualization){
        self.visualizations.append(setting)
        
        if self.delegate == nil{
            needsRefresh = true
        }
        //self.delegate?.onSettingChange()
    }
    
    func removeSetting(index:Int){
        self.visualizations.remove(at: index)
        //self.delegate?.onSettingChange()
    }
    
    func updateDefaults(){
        let vizDict = self.visualizations.map { (viz) -> [String:Any] in
            var dict = viz.settings
            dict["musicAssetURL"] = (dict["musicAssetURL"] != nil) ? dict["musicAssetURL"]! : ("") as Any
           
            return dict
        }
        print(vizDict)
        let encodedData = NSKeyedArchiver.archivedData(withRootObject: vizDict)
        UserDefaults.standard.set(encodedData, forKey: "ARVisualizations")
    }
    
    func recreateVisualizations(){
        guard let decoded  = UserDefaults.standard.object(forKey: "ARVisualizations") as? Data else {
            return
        }
        if let vizDict = NSKeyedUnarchiver.unarchiveObject(with: decoded) as? [[String:Any]]{
            self.visualizations = [ARVisualization]()
            vizDict.forEach({ (dict) in
                let viz = ARVisualization(name: dict["name"] as! String)
                viz.bounds = dict["bounds"] as! Float
                viz.box_dimensions = dict["box_dimensions"] as! Float
                viz.frame_count = dict["frame_count"] as! Int
                viz.increment = dict["increment"] as! Float
                if let url = dict["musicAssetURL"] as? URL{
                    viz.musicAssetURL = url
                }
                viz.num_nodes = dict["num_nodes"] as! Int
                viz.num_rings = dict["num_rings"] as! Int
                viz.ring_separation = dict["ring_separation"] as! Float
                viz.anime = (dict["anime"] as? Bool) ?? false
                
                self.addSetting(setting: viz)
            })
            
            self.delegate?.onSettingChange()
        }
    }

}
