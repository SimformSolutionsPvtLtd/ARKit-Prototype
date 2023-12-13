//
//  AVReadARObjectVC.swift
//  ios12 Sampler
//
//  Created by Testing on 13/06/18.
//  Copyright © 2018 Testing. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class AVReadARObjectVC: UIViewController,ARSCNViewDelegate {
    
    @IBOutlet weak var sceneView: ARSCNView!
    var viewObj = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 89))
    var objectURL:URL?
    var imageURL:URL?
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpSceneView()
        viewObj.backgroundColor = UIColor.clear
        let jeremyGif = UIImage.gifImageWithName("Loky")
        let imageView = UIImageView(image: jeremyGif)
        viewObj = imageView
        viewObj.contentMode = .scaleAspectFit
        // Do any additional setup after loading the view.
    }
    
    func setUpSceneView() {
        sceneView.delegate = self
        sceneView.showsStatistics = true
        do {
            let configuration = ARWorldTrackingConfiguration()
            if imageURL != nil {
                let imageData = try Data(contentsOf: imageURL!)
                let image = UIImage(data: imageData)
                configuration.detectionImages = Set([ARReferenceImage((image?.cgImage)!, orientation: CGImagePropertyOrientation.up, physicalWidth: 100)])
            }
            if objectURL != nil {
                configuration.detectionObjects = Set([try ARReferenceObject(archiveURL: objectURL!)])
            }
            sceneView.session.run(configuration)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "Found Object", message: "This is your object.", preferredStyle: .alert)
            let action1 = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
                print("You've pressed default");
            }
            alertController.addAction(action1)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()

        if let imageAnchor = anchor as? ARImageAnchor {
            let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
            plane.firstMaterial?.diffuse.contents = UIColor(white: 1, alpha: 0.8)
            let material = SCNMaterial()
            material.diffuse.contents = viewObj
            plane.materials = [material]
            let planeNode = SCNNode(geometry: plane)
            planeNode.eulerAngles.x = -.pi / 2
            
            node.addChildNode(planeNode)
            
        }
        else{
            //planeNode.eulerAngles = SCNVector3Make(0,0,Float(-M_PI_2))
            
            let shipScene = SCNScene(named: "art.scnassets/ArrowB.scn")!
            let shipNode = shipScene.rootNode.childNodes.first!
            shipNode.position =  SCNVector3.positionFromTransform(anchor.transform)
            shipNode.position.y = 0.25
            print(shipNode.position)
            sceneView.scene.rootNode.addChildNode(shipNode)
        }
        return node
    }
    
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
