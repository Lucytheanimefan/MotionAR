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

//The green axis represents Y (take a mental note, Y points up)
//The red axis represents X
//The blue axis represents Z

//This position is relative to the camera. Positive x is to the right. Negative x is to the left.
//Positive y is up. Negative y is down. Positive z is backward. Negative z is forward.
class ARViewController: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!
    var configuration: ARWorldTrackingConfiguration!
    
    var activityManager:CMMotionActivityManager!
    var motionManager:CMMotionManager!
    
    var nodes:[SCNNode] = [SCNNode]()
    var light:SCNLight!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSceneView()
        self.activityManager = CMMotionActivityManager()
        self.motionManager = CMMotionManager()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.startSession()
        self.createLight()
        self.addBox()
        self.beginMotionData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }
    
    func setupSceneView(){
        self.sceneView.scene = SCNScene()
        self.sceneView.delegate = self
        #if DEBUG
        self.sceneView.showsStatistics = true
        self.sceneView.debugOptions = ARSCNDebugOptions.showWorldOrigin
        #endif
        self.sceneView.scene.physicsWorld.contactDelegate = self
    
    }

    func startSession() {
        configuration = ARWorldTrackingConfiguration()
        //currenly only planeDetection available is horizontal.
        configuration!.planeDetection = ARWorldTrackingConfiguration.PlaneDetection.horizontal
        sceneView.session.run(configuration!, options: [ARSession.RunOptions.removeExistingAnchors,
                                                        ARSession.RunOptions.resetTracking])
    }
    
    func createLight(){
        self.light = SCNLight()
        light.type = .omni
        light.castsShadow = true
        light.shadowRadius = 2
        self.sceneView.pointOfView?.light = light
    }
    
    func addBox(){
        let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        
        let boxNode = SCNNode()
        boxNode.geometry = box
        boxNode.position = SCNVector3(0, 0, -0.2)
        
        self.nodes.append(boxNode)
        self.sceneView.addNode(node: boxNode)
    }
    
    func beginMotionData(){
        self.motionManager.deviceMotionUpdateInterval = TimeInterval(1)
        self.motionManager.startDeviceMotionUpdates(to: OperationQueue.current!) { (deviceMotion, error) in
            guard error == nil else{
                print(error)
                return
            }
            
            self.nodes.forEach({ (node) in
                if let geometry = node.geometry as? SCNBox{
                    let xAccel = abs((deviceMotion?.userAcceleration.x)!) * 10
                    print(xAccel)
                    geometry.chamferRadius = CGFloat(xAccel)
                }
            })
            
            
        }
        
        
    }

}

extension ARViewController: SCNPhysicsContactDelegate{
    func physicsWorld(_ world: SCNPhysicsWorld, didUpdate contact: SCNPhysicsContact) {
        
    }
}

extension ARSCNView{
    func addNode(node:SCNNode){
        self.scene.rootNode.addChildNode(node)
    }
}

extension ARViewController:ARSCNViewDelegate{
    
    
}
