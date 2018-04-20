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
import QuartzCore

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
    
    private var _currentActivity:String! = ""
    var currentActivity:String{
        set{
            self._currentActivity = newValue
            DispatchQueue.main.async {
                self.debugView.text.append(self.timestamp + ": " + newValue + "\n") //newValue
                self.debugView.simple_scrollToBottom()
            }
        }
        get{
            return self._currentActivity
        }
    }
    
    var mfcc:[Float]!
    
    lazy var timestamp:String = {
        let now = Date()
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "HH:mm"
        let dateString = formatter.string(from: now)
        return dateString
    }()
    
    @IBOutlet weak var debugView: UITextView!
    
    
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
        //print(ARVizSettings.settings)
        self.startSession()
        self.createLight()
        
        self.createRings(numRings: /*Constants.NUM_RINGS*/ARVizSettings.num_rings, separationDistance: /*Constants.RING_SEPARATION*/ARVizSettings.ring_separation)
        self.beginMotionData()
        self.beginMotionCategorization()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    func incrementAngle(adjustment:Float = 0) -> Float {
        return (4*Float.pi + adjustment) / Float(ARVizSettings.num_nodes)
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true) {
            if (self.ARVizSettings.musicAssetURL != nil){
                //self.musicAssetURL = nil
                self.audioTransformer.cancel()
            }
        }
    }
    
    @IBAction func debugViewAction(_ sender: UIBarButtonItem) {
        let frame = debugView.frame
        
        debugView.frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.width, height: (frame.height < 120) ? 120 : 0)
        
    }
    
    
    // MARK: Scene setup
    func setupSceneView(){
        self.sceneView.scene = SCNScene()
        self.sceneView.delegate = self
        //        #if DEBUG
        self.sceneView.showsStatistics = true
        //            self.sceneView.debugOptions = ARSCNDebugOptions.showWorldOrigin
        //        #endif
        self.sceneView.debugOptions.insert(.showWireframe)
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
        //startRecording()
    }
    
    
    @IBAction func stopRecording(_ sender: UIBarButtonItem) {
        //stopRecording()
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
        
        //box.firstMaterial?.fillMode = .lines
        
        let boxNode = SCNNode(geometry: box)
        boxNode.position = SCNVector3(0, 0, -0.2)
        if let name = name{
            boxNode.name = name
        }
        
        return boxNode
    }
    
    func createSphere()->SCNNode{
        let sphere = SCNSphere(radius: 0.1)
        sphere.firstMaterial?.fillMode = .lines
        let node = SCNNode(geometry: sphere)
        return node
    }
    
    // MARK: Create Rings
    func createRings(numRings:Int, separationDistance:Float){
        for i in -numRings/2 ..< numRings/2{
            let nodes = addRing(radius: self.ARVizSettings.ring_radius, y: Float(i)*separationDistance, name:"ring_\(i + numRings/2)")
            self.ringNodes.append(nodes)
        }
    }
    
    func addRing(nodes:[SCNNode]? = nil, radius:Float = 0.5, x:Float? = nil, y:Float? = nil, z:Float? = nil, name:String? = nil) -> [SCNNode]{
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
            //print("Rotation: \(xRot), \(yRot), \(zRot)")
            //print("Acceleration: \(xAccel),\(yAccel),\(zAccel)")
            #endif
            
            let (xGravity, yGravity, zGravity) = deviceMotion.absGravity()
            let (xPosGravity, yPosGravity, zPosGravity) = deviceMotion.positionGravity()
            
            for (j, nodes) in self.ringNodes.enumerated(){
                for (i, node) in nodes.enumerated(){
                    if let geometry = node.geometry as? SCNBox{
                        let minDimension = min(geometry.height, geometry.width, geometry.length)/2
                        geometry.chamferRadius = CGFloat(yGravity)*minDimension
                    }
                    if (self.option == "motion"){
                        let accelColor = UIColor(red: xAccel, green: yAccel, blue: zAccel, alpha: 1)
                        node.geometry?.setColor(color: accelColor)
                    }
                    
                    // For the middle ring, rotate the nodes
                    //                    if (j == self.ringNodes.count/2)
                    //                    {
                    //                        let rot = max(xRot, yRot, zRot)
                    //                        let xN = Float(cos(Float((i+1)/2) * self.incrementAngle(adjustment: rot))) * Constants.RADIUS //TODO: change radius
                    //                        let zN = Float(sin(Float((i+1)/2) * self.incrementAngle(adjustment: rot))) * Constants.RADIUS
                    //                        let yN = Float(0)//Float((i+1))*self.ARVizSettings.ring_separation
                    //
                    //                        node.position = SCNVector3Make(xN, yN, zN)
                    //                    }
                }
            }
        }
    }
    
    func changeRingRadii(radii:[Float]){
        for (i, ring) in self.ringNodes.enumerated(){
            for (j, node) in ring.enumerated(){
                let radius:Float = (radii.count < i) ? Constants.RADIUS : radii[i]
                let xN = Float(cos(Float((j+1)/2) * self.incrementAngle())) * radius //TODO: change radius
                let zN = Float(sin(Float((j+1)/2) * self.incrementAngle())) * radius
                let yN = Float(i) * self.ARVizSettings.ring_separation //Float((i+1))*self.ARVizSettings.ring_separation
                node.position = SCNVector3Make(xN, yN, zN)
            }
        }
    }
    
    func beginMotionCategorization(){
        self.activityManager.startActivityUpdates(to: OperationQueue.current!) { (activity) in
            guard let activity = activity else {
                return
            }
            if (activity.walking){
                guard self.currentActivity != "Walking" else {
                    return
                }
                self.currentActivity = "Walking"
                
                // Make it a dome/sphere thing!
                let radiusFactor = Constants.RADIUS/Float(self.ringNodes.count)
                var radii = [Float]()
                let midpoint = self.ringNodes.count/2
                for i in 0..<self.ringNodes.count{
                    radii.append(Float(abs(midpoint - i)) * radiusFactor)
                }
                self.changeRingRadii(radii: radii)
            }
            else if (activity.stationary){
                guard self.currentActivity != "Stationary" else {
                    return
                }
                self.currentActivity = "Stationary"
                
                // Make it a dome/sphere thing!
                self.changeRingRadii(radii: [])
                //                for (i, ring) in self.ringNodes.enumerated(){
                //                    for (j, node) in ring.enumerated(){
                //                        if (i == 0 || i == self.ringNodes.count - 1){
                //                            let xN = Float(cos(Float((j+1)/2) * self.incrementAngle())) * Constants.RADIUS/2 //TODO: change radius
                //                            let zN = Float(sin(Float((j+1)/2) * self.incrementAngle())) * Constants.RADIUS/2
                //                            let yN = Float(i) * self.ARVizSettings.ring_separation
                //                            node.position = SCNVector3Make(xN, yN, zN)
                //                        }
                //                    }
                //                }
            }
            else if (activity.running){
                guard self.currentActivity != "running" else {
                    return
                }
                self.currentActivity = "Running"
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
    
    func pushNodeOutward(node:SCNNode, signValues:SCNVector3, physics:Bool){
        let rand = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
        let action = SCNAction.move(by: SCNVector3Make(signValues.x * ARVizSettings.increment * Float(rand) , 0, signValues.z * ARVizSettings.increment * Float(rand) ), duration: 1.5 )
        action.timingMode = .easeInEaseOut
        
        node.runAction(action, completionHandler: {
            if (physics){
                node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
            }
        })
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        guard ARVizSettings.gamify else {
            return
        }
        
        self.currentPosition = frame.camera.transform.position()
        //print("Current position: \(currentPosition)")
        
        for (_, node) in self.nodes.enumerated(){
            let nodePosition = node.position
            
            // Collision detected
            if self.withinBounds(position1: nodePosition, position2: currentPosition){
                print("--Within bounds!!!!")
                
                // Move the node out a bit if I collide with it
                let signValues = nodePosition.signValue()
                
                
                if let collisionParticleSystem = SCNParticleSystem(named: "Collision", inDirectory: nil){
                    node.addParticleSystem(collisionParticleSystem)
                    pushNodeOutward(node: node, signValues: signValues, physics: true)
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
            ringNodes.forEach({ (nodes) in
                updateNodeScalesWithFFT(index: index, magnitude: magnitude, nodes: nodes)
            })
        }
    }
    
    func updateNodeScalesWithFFT(index:Int, magnitude:Float, nodes:[SCNNode]){
        guard index < nodes.count else {
            print("Index \(index) is greater than # of nodes \(nodes.count)")
            return
        }
        let m = 2*pow(magnitude, 1/3) //magnitude.squareRoot()
        
        let s = SCNVector3Make(m, m, m)
        #if DEBUG
        //print("Node: \(index), Scale: \(s.description())")
        #endif
        nodes[index].scale = s
    }
    
    
}
