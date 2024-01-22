//
//  ARImageLocator.swift
//  ios12 Sampler
//
//  Created by Dhruvil Vora on 10/01/24.
//  Copyright © 2024 Testing. All rights reserved.
//

import Foundation
import ARKit

class ARImageLocator: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!

    @IBOutlet weak var blurVIew: UIVisualEffectView!

    lazy var statusViewController: StatusViewController = {
        children.lazy.compactMap({ $0 as? StatusViewController }).first!
    }()

    /// Need to create a serial queue for thread safety, when modifying scenekit  node graph
    let serialQueue = DispatchQueue(label: "\(Bundle.main.bundleIdentifier ?? "") + .serialScenekitQueue")

    /// Session accessor which is hold by sceneview
    var session: ARSession {
        sceneView.session
    }

    var isRestartAvailable = true

    // MARK: View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        sceneView.delegate = self

        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        sceneView.scene = scene

        sceneView.session.delegate = self

        // Hook up status view controller callback(s).
        statusViewController.restartExperienceHandler = { [unowned self] in
            self.restartExperience()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        /// Prevent screen from being dimmed after it's let ideal for sometime
        UIApplication.shared.isIdleTimerDisabled = true
        statusViewController.scheduleGenericMessage(genericMsg: "Look for an image", duration: 7.5,
                                                    autoHide: true, messageType: .cameraQualityInfo)
        resetTracking()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        session.pause()
    }

    /// Create a new arconfig to run on a `session`
    func resetTracking() {

        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            fatalError("Didn't found any resourcses")
        }
        let config = ARWorldTrackingConfiguration()
        /// Need to provide detection images
        config.detectionImages = referenceImages
        session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }

    private func restartExperience() {
        guard isRestartAvailable else { return }
        isRestartAvailable = false
        statusViewController.showHideResetButton(isHidden: isRestartAvailable)
        statusViewController.removeAllTimers()

        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self else { return }
            self.isRestartAvailable = true
            self.statusViewController.showHideResetButton(isHidden: self.isRestartAvailable)
        }
    }
}

extension ARImageLocator: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        serialQueue.async {
            // first create a plane from the added anchor
            let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width,
                                 height: imageAnchor.referenceImage.physicalSize.height)
            let planeNode = SCNNode(geometry: plane)
            planeNode.opacity = 0.25

            // As SCNPlane is a 2d it is vertically oriented and the ARImageAnchor is horizontally oriented
            /// So by default SCNPlane is in a 2D format whose orientation is vertical & image anchor being 3D format its
            ///  horizontally align so inorder to matchb with imageanchor we need to rotate the plane's angle
            planeNode.eulerAngles.x = -.pi / 2

            node.addChildNode(planeNode)
        }
        DispatchQueue.main.async {
            let name = imageAnchor.referenceImage.name
            print("Image Name :- ",name)
            self.animateObject(node)
        }
    }

    func animateObject(_ node: SCNNode) {

        guard let nodeToAnimate = sceneView.scene.rootNode.childNode(withName: "ship", recursively: true) else {
            return
        }

        //        let forwardAction = SCNAction.moveBy(x: 0, y: 0, z: 5, duration: 1.0)
        //        let rotateAction1 = SCNAction.rotateBy(x: -.pi/2,y: 0, z: 0, duration: 2.0)
        //        let backwardAction = SCNAction.moveBy(x: 0, y: 0, z: -5, duration: 1.0)
        //        let rotateAction2 = SCNAction.rotateBy(x: -.pi/2,y: 0, z: 0, duration: 2.0)
        //        let abc = SCNAction.group([backwardAction, rotateAction1])
        //        let sequenceAction = SCNAction.sequence([forwardAction, rotateAction1, backwardAction, rotateAction2])

        let forwardAction = SCNAction.moveBy(x: 0, y: 0, z: 5, duration: 1.0)
        let rotateAction1 = SCNAction.rotateBy(x: (-.pi),y: 0, z: 0, duration: 5.0)
        let backwardAction = SCNAction.moveBy(x: 0, y: 0, z: -5, duration: 1.0)
        let rotateAction2 = SCNAction.rotateBy(x: .pi/2,y: 0, z: 0, duration: 2.0)
        let rotation = SCNAction.rotateBy(x: 0,y: 0, z: .pi, duration: 2.0)
        var verticalPosition0: CGFloat = 0.0
        // Create a custom action to update the position based on a parabolic function
        let parabolicAction = SCNAction.customAction(duration: 2) { (node, elapsedTime) in
            // Calculate the vertical position using a parabolic function
            verticalPosition0 = 0.5 * 9.8 * pow(elapsedTime, 1)
            print("vertical Pos :- ", verticalPosition0)
            // Update the node's position based on the parabolic function
            node.position = SCNVector3(nodeToAnimate.position.x, 
                                       Float(verticalPosition0) > 4.9 ? (9.8 - Float(verticalPosition0)) : Float(verticalPosition0),
                                       -Float(verticalPosition0))
        }

        let parabolicBackAction = SCNAction.customAction(duration: 2) { (node, elapsedTime) in
            // Calculate the vertical position using a parabolic function
            let verticalPosition = -0.5 * 9.8 * pow(elapsedTime, 1)
            print("vertical Pos :- ", verticalPosition)
            // Update the node's position based on the parabolic function
            node.position = SCNVector3(Float(node.position.x), Float(verticalPosition), node.position.z)
        }
        //        let sequenceAction = SCNAction.sequence([forwardAction, rotateAction1, backwardAction, rotateAction1])

        let groupAction1 = SCNAction.group([forwardAction, rotation, parabolicAction])
        let groupAction2 = SCNAction.group([rotateAction1, backwardAction])
        let sequenceAction = SCNAction.sequence([groupAction1])

        let repeatAction = SCNAction.repeatForever(parabolicAction.reversed())

        nodeToAnimate.runAction(repeatAction)
    }

    var imageHighlightAction: SCNAction {
        return .sequence([
            .wait(duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
            .fadeOpacity(to: 0.15, duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
            .fadeOut(duration: 0.5),
            .removeFromParentNode()
        ])
    }
}

