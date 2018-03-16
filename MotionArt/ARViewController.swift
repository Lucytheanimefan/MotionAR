//
//  ARViewController.swift
//  MotionArt
//
//  Created by Lucy Zhang on 3/16/18.
//  Copyright © 2018 Lucy Zhang. All rights reserved.
//

import UIKit
import ARKit
import CoreMotion

class ARViewController: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!
    
    var activityManager:CMMotionActivityManager!
    var motionManager:CMMotionManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.activityManager = CMMotionActivityManager()
        self.motionManager = CMMotionManager()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }
    
    func setupSceneView(){
         self.sceneView.scene.physicsWorld.contactDelegate = self
    }

    func beginMotionData(){
        self.motionManager.startDeviceMotionUpdates(to: OperationQueue.current!) { (deviceMotion, error) in
            guard error == nil else{
                print(error)
                return
            }
            
        }
        
        
    }

}

extension ARViewController: SCNPhysicsContactDelegate{
    func physicsWorld(_ world: SCNPhysicsWorld, didUpdate contact: SCNPhysicsContact) {
        
    }
}
