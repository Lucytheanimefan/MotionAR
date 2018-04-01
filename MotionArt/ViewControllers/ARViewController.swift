//
//  ARViewController.swift
//  MotionArt
//
//  Created by Lucy Zhang on 3/16/18.
//  Copyright © 2018 Lucy Zhang. All rights reserved.
//

import UIKit
import ReplayKit
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
    var altitudeManager:CMAltimeter!
    
    var nodes:[SCNNode] = [SCNNode]()
    
    // Array of all the nodes per ring: index 0 is ring 0
    var ringNodes = [[SCNNode]]()
    var light:SCNLight!
    
    let recorder = RPScreenRecorder.shared()
    
    var deviceMotion:CMDeviceMotion?
    
    var ARVizSettings:ARVisualization!
    
    var option:String!
    var musicAssetURL:URL?
    
    var audioTransformer:AudioTransformer!
    
    var currentPosition:SCNVector3!
    
    lazy var incrementAngle:Float = {
        return (4*Float.pi) / Float(ARVizSettings.num_nodes)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSceneView()
        self.audioTransformer = AudioTransformer()
        self.activityManager = CMMotionActivityManager()
        self.motionManager = CMMotionManager()
        self.altitudeManager = CMAltimeter()
        audioTransformer.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print(ARVizSettings.settings)
        self.startSession()
        self.createLight()
        
        self.createRings(numRings: /*Constants.NUM_RINGS*/ARVizSettings.num_rings, separationDistance: /*Constants.RING_SEPARATION*/ARVizSettings.ring_separation)
        self.beginMotionData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true) {
            if (self.ARVizSettings.musicAssetURL != nil){
                //self.musicAssetURL = nil
                self.audioTransformer.cancel()
            }
        }
    }
    
    // MARK: Scene setup
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
        configuration!.planeDetection = ARWorldTrackingConfiguration.PlaneDetection.horizontal
        sceneView.session.delegate = self
        sceneView.session.run(configuration!, options: [ARSession.RunOptions.removeExistingAnchors,
                                                        ARSession.RunOptions.resetTracking])
    }
    
    // MARK: Recording
    @IBAction func startRecording(_ sender: UIBarButtonItem) {
        if let url = ARVizSettings.musicAssetURL{
            print("Music URL: \(url)")
            audioTransformer.begin(file: url)
        }
        startRecording()
    }
    
    
    @IBAction func stopRecording(_ sender: UIBarButtonItem) {
        stopRecording()
    }
    
    func startRecording(){
        guard recorder.isAvailable else {
            print("Recording is not available at this time.")
            return
        }
        
        recorder.startRecording { (error) in
            guard error == nil else {
                print("There was an error starting the recording: \(error.debugDescription)")
                return
            }
        }
    }
    
    func stopRecording(){
        recorder.stopRecording { (preview, error) in
            guard preview != nil else {
                print("Preview controller is not available.")
                return
            }
            
            let alert = UIAlertController(title: "Recording Finished", message: "Would you like to edit or delete your recording?", preferredStyle: .alert)
            
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { (action: UIAlertAction) in
                self.recorder.discardRecording(handler: { () -> Void in
                    print("Recording suffessfully deleted.")
                })
            })
            
            let editAction = UIAlertAction(title: "Edit", style: .default, handler: { (action: UIAlertAction) -> Void in
                preview?.previewControllerDelegate = self
                self.present(preview!, animated: true, completion: nil)
            })
            
            alert.addAction(editAction)
            alert.addAction(deleteAction)
            self.present(alert, animated: true, completion: nil)
            
        }
    }
    
    //MARK: SceneKit objects
    func createLight(){
        self.light = SCNLight()
        light.type = .omni
        light.castsShadow = true
        light.shadowRadius = 2
        self.sceneView.pointOfView?.light = light
    }
    
    func addBox(){
        let boxNode = createBox()
        addNode(node: boxNode)
    }
    
    func createBox(name:String? = nil)->SCNNode{
        let box = SCNBox(width: CGFloat(ARVizSettings.box_dimensions), height: CGFloat(ARVizSettings.box_dimensions), length: CGFloat(ARVizSettings.box_dimensions), chamferRadius: 0)
        if (ARVizSettings.name.lowercased() == "anime"){
            box.setImage(image: #imageLiteral(resourceName: "penguinCucumber"))
        }
        let boxNode = SCNNode(geometry: box)
        boxNode.position = SCNVector3(0, 0, -0.2)
        if let name = name{
            boxNode.name = name
        }
        return boxNode
    }
    
    func createSphere()->SCNNode{
        let sphere = SCNSphere(radius: 0.1)
        let node = SCNNode(geometry: sphere)
        return node
    }
    
    // MARK: Create Rings
    func createRings(numRings:Int, separationDistance:Float){
        for i in -numRings/2 ..< numRings/2{
            let nodes = addRing(y: Float(i)*separationDistance, name:"ring_\(i + numRings/2)")
            self.ringNodes.append(nodes)
        }
    }
    
    func addRing(nodes:[SCNNode]? = nil, radius:Float = 1, x:Float? = nil, y:Float? = nil, z:Float? = nil, name:String? = nil) -> [SCNNode]{
        print(name)
        var myNodes = [SCNNode]()
        if let nodes = nodes{
            myNodes = nodes
        }
        else{
            for _ in 0 ..< ARVizSettings.num_nodes{
                myNodes.append(createBox(name: name))
            }
        }
        
        let incrementAngle = (4*Float.pi) / Float(myNodes.count)
        var returnNodes = [SCNNode]()
        for (i, node) in myNodes.enumerated(){
            let xN = Float(cos(Float(i/2) * incrementAngle)) * radius //TODO: change radius
            let zN = Float(sin(Float(i/2) * incrementAngle)) * radius
            let yN = zN
            if let x = x{
                node.position = SCNVector3Make(x, yN, zN)
            }
            else if let y = y{
                node.position = SCNVector3Make(xN, y, zN)
            }
            else if let z = z{
                node.position = SCNVector3Make(xN, yN, z)
            }
            else{
                node.position = SCNVector3Make(Float(xN), 0, Float(zN))
            }
            returnNodes.append(node)
            addNode(node: node)
        }
        return returnNodes
    }
    
    func addNode(node:SCNNode){
        self.nodes.append(node)
        self.sceneView.addNode(node: node)
    }
    
    // MARK: Motion
    func beginMotionData(){
        var oldIndex:Int = -1
        self.motionManager.startDeviceMotionUpdates(to: OperationQueue.current!) { (deviceMotion, error) in
            guard error == nil else{
                print(error.debugDescription)
                return
            }
            
            guard let deviceMotion = deviceMotion else {
                return
            }
            self.deviceMotion = deviceMotion
            
            let (xAccel, yAccel, zAccel) = deviceMotion.normalizedAcceleration()
            
            let (roll, pitch, yaw) = deviceMotion.rollPitchYaw()
            
            let (xRot, yRot, zRot) = deviceMotion.rotationRateFloat()
            
            #if DEBUG
                //print("Acceleration: \(xAccel),\(yAccel),\(zAccel)")
            #endif
            
            let (xGravity, yGravity, zGravity) = deviceMotion.absGravity()
            
            let (xPosGravity, yPosGravity, zPosGravity) = deviceMotion.positionGravity()
           
            for (i, node) in self.nodes.enumerated(){
                if let geometry = node.geometry as? SCNBox{
                    let minDimension = min(geometry.height, geometry.width, geometry.length)/2
                    geometry.chamferRadius = CGFloat(yGravity)*minDimension
                }
                
                if (self.option == "motion"){
                    let accelColor = UIColor(red: xAccel, green: yAccel, blue: zAccel, alpha: 1)
                    node.geometry?.setColor(color: accelColor)
                }
   
                
                if let ringIndex = node.ringIndex(){
                    if (oldIndex != ringIndex){
                        print("\(oldIndex), \(ringIndex)")
                        oldIndex = ringIndex
                    }
                    switch ringIndex{
                    case 0: // top ring
                        return
                    //node.rotation = SCNVector4Make(roll, pitch, yaw, xPosGravity)
                    case 1:
                        print("Move")
                        let xN = Float(cos(Float((i+1)/2) * self.incrementAngle)) * Constants.RADIUS //TODO: change radius
                        let zN = Float(sin(Float((i+1)/2) * self.incrementAngle)) * Constants.RADIUS
                        let yN = Float((i+1))*self.ARVizSettings.ring_separation
                        let action = SCNAction.move(to: SCNVector3Make(xN, yN, zN), duration: 1)
                        node.runAction(action, completionHandler: {
                            print("Done action")
                        })
                    case 2:
                        return
                    //node.rotation = SCNVector4Make(roll, pitch, yaw, yPosGravity)
                    default:
                        //node.rotation = SCNVector4Make(0, 0, 0, 0)
                        print("Not one of the 3 rings")
                    }
                }
            }
        }
    }
    
    func beginMotionCategorization(){
        self.activityManager.startActivityUpdates(to: OperationQueue.current!) { (activity) in
            guard let activity = activity else {
                return
            }
            if (activity.walking){
                
            }
            else if (activity.stationary){
                
            }
        }
    }
    
    func beginAltitudeData(){
        self.altitudeManager.startRelativeAltitudeUpdates(to: OperationQueue.current!) { (altitude, error) in
            guard error == nil && altitude != nil else {
                print("Error with altimeter: \(error.debugDescription)")
                return
            }
            //The change in altitude (in meters) since the first reported event.
            //altitude?.relativeAltitude
        }
    }
    
    func addVector3(lhv:SCNVector3, rhv:SCNVector3) -> SCNVector3 {
        return SCNVector3(lhv.x + rhv.x, lhv.y + rhv.y, lhv.z + rhv.z)
    }
    
    func subtractVector3(lhv:SCNVector3, rhv:SCNVector3) -> SCNVector3 {
        return SCNVector3(lhv.x - rhv.x, lhv.y - rhv.y, lhv.z - rhv.z)
    }
    
    func withinBounds(position1:SCNVector3, position2:SCNVector3) -> Bool{
        return (abs(position1.x - position2.x) < ARVizSettings.bounds &&
            abs(position1.y - position2.y) < ARVizSettings.bounds &&
            abs(position1.z - position2.z) < ARVizSettings.bounds)
    }
    
    func cleanScene() {
        for (i, node) in self.nodes.enumerated() {
            if node.presentation.position.y < -1*(Float(ARVizSettings.num_rings/2) * ARVizSettings.ring_separation) {
                print("Remove a node")
                node.removeFromParentNode()
                self.nodes.remove(at: i)
            }
        }
    }
    
}

// MARK: ARViewController Extensions
extension ARViewController: SCNPhysicsContactDelegate{
}

extension ARViewController:RPPreviewViewControllerDelegate{
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        dismiss(animated: true, completion: nil)
    }
}

extension ARViewController:ARSessionDelegate{
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        self.currentPosition = frame.camera.transform.position()
        //print("Current position: \(currentPosition)")
        
        for (i, node) in self.nodes.enumerated(){
            let nodePosition = node.position
            
            // Collision detected
            if self.withinBounds(position1: nodePosition, position2: currentPosition){
                print("--Within bounds!!!!")
                //print("Node position: \(nodePosition)")
                
                // Move it out a bit
                let signValues = nodePosition.signValue()
                
                // Create collision nodes
                if let collisionParticleSystem = SCNParticleSystem(named: "Collision", inDirectory: nil){
                    node.addParticleSystem(collisionParticleSystem)
                    
                    let rand = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
                    let action = SCNAction.move(by: SCNVector3Make(signValues.x * ARVizSettings.increment * Float(rand) , 0, signValues.z * ARVizSettings.increment * Float(rand) ), duration: 1.5 )
                    action.timingMode = .easeInEaseOut
                    
                    node.runAction(action, completionHandler: {
                        node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
                    })
                }
                
            }
        }
    }
}

// MARK: Extensions
extension ARViewController:ARSCNViewDelegate{
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        cleanScene()
    }
    
}



extension ARViewController: AudioTransformerDelegate{
    func onPlay() {
        
    }
    
    func dealWithFFTMagnitudes(magnitudes: [Float]) {
        //let max = magnitudes.max()
        for (index, magnitude) in magnitudes.enumerated()
        {
            //let middleIndex = ringNodes.count/2
            ringNodes.forEach({ (nodes) in
                updateNodeScalesWithFFT(index: index, magnitude: magnitude, nodes: nodes)
            })
            //updateNodeScalesWithFFT(index: index, magnitude: magnitude, nodes: ringNodes[middleIndex])
        }
    }
    
    func updateNodeScalesWithFFT(index:Int, magnitude:Float, nodes:[SCNNode]){
        guard index < nodes.count else {
            print("Index \(index) is greater than # of nodes \(nodes.count)")
            return
        }
        let m = magnitude.squareRoot()
        
        let s = SCNVector3Make(m, m, m)
        #if DEBUG
            //print("Node: \(index), Scale: \(s.description())")
        #endif
        nodes[index].scale = s
    }
    
    
}
