//
//  ViewController.swift
//  MeasureTest
//
//  Created by Mani on 9/26/18.
//  Copyright © 2018 Mani. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    var firstBox : SCNNode?
    var secondBox : SCNNode?
    
    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var targetView: UIView!
    
    @IBOutlet weak var measurementLabel: UILabel!
    
    @IBOutlet weak var theButton: UIButton!
    
    @IBAction func buttonTapped(_ sender: Any) {
        if firstBox == nil {
            firstBox = addBox()
            if firstBox != nil {
                theButton.setTitle("Set End Point", for: .normal)
            }
        } else if secondBox == nil {
            secondBox = addBox()
            if secondBox != nil {
                //calculation
                calcDistance()
                theButton.setTitle("Reset", for: .normal)
            }
        } else {
            firstBox?.removeFromParentNode()
            secondBox?.removeFromParentNode()
            firstBox = nil
            secondBox = nil
            measurementLabel.text = ""
            theButton.setTitle("Set Start Point", for: .normal)
        }
        saveMap()
    }
    
    func calcDistance() {
        if let firstBox = firstBox {
            if let secondBox = secondBox {
                let vector = SCNVector3Make(secondBox.position.x - firstBox.position.x, secondBox.position.y - firstBox.position.y, secondBox.position.z - firstBox.position.z)
                let distance = sqrt(vector.x*vector.x+vector.y*vector.y+vector.z*vector.z)
                measurementLabel.text = "\(distance)m"
            }
        }
        
    }
    
    func addBox() -> SCNNode? {
        let userTouch = sceneView.center
        let testResults = sceneView.hitTest(userTouch, types: .featurePoint)
        if let theResult = testResults.first {
            let box = SCNBox(width: 0.005, height: 0.005, length: 0.005, chamferRadius: 0.001)
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.green
            box.firstMaterial = material
            
            let boxNode = SCNNode(geometry: box)
            boxNode.position = SCNVector3(theResult.worldTransform.columns.3.x, theResult.worldTransform.columns.3.y, theResult.worldTransform.columns.3.z)
            sceneView.scene.rootNode.addChildNode(boxNode)
            return boxNode
        }
        return nil
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        measurementLabel.text = ""
    }
    
    //save a world
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if frame.worldMappingStatus == .mapped {
            theButton.isEnabled = true
        } else {
            theButton.isEnabled = false
        }
    }
    
    func saveMap() {
        sceneView.session.getCurrentWorldMap { (map, error) in
            if error != nil {
                if let map = map {
                    if let mapData = try?NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true){
                        UserDefaults.standard.set(mapData, forKey:"map")
                        UserDefaults.standard.synchronize()
                    }
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal //only makes measurement on the planes

        if let mapData = UserDefaults.standard.data(forKey: "map") {
            if let map = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: mapData) {
                configuration.initialWorldMap = map
            }
        }
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
