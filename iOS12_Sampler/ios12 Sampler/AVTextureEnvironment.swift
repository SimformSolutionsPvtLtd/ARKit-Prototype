/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main view controller for the AR experience.
*/

import UIKit
import SceneKit
import ARKit
import MultipeerConnectivity

class AVTextureEnvironment: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    // MARK: - IBOutlets
    
    @IBOutlet weak var sessionInfoView: UIView!
    @IBOutlet weak var sessionInfoLabel: UILabel!
    @IBOutlet weak var sceneView: ARSCNView!
    
    // MARK: - View Life Cycle
    
    var multipeerSession: MultipeerSession!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("""
                ARKit is not available on this device. For apps that require ARKit
                for core functionality, use the `arkit` key in the key in the
                `UIRequiredDeviceCapabilities` section of the Info.plist to prevent
                the app from installing. (If the app can't be installed, this error
                can't be triggered in a production scenario.)
                In apps where AR is an additive feature, use `isSupported` to
                determine whether to show UI for launching AR experiences.
            """) // For details, see https://developer.apple.com/documentation/arkit
        }
        
        // Start the view's AR session.
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        configuration.environmentTexturing = ARWorldTrackingConfiguration.EnvironmentTexturing.automatic
        sceneView.session.run(configuration)
        
        // Set a delegate to track the number of plane anchors for providing UI feedback.
        sceneView.session.delegate = self
        
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        // Prevent the screen from being dimmed after a while as users will likely
        // have long periods of interaction without touching the screen or buttons.
        UIApplication.shared.isIdleTimerDisabled = true
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's AR session.
        sceneView.session.pause()
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let name = anchor.name, name.hasPrefix("panda") {
            node.addChildNode(loadRedPandaModel())
        }
    }
    // MARK: - Multiuser shared session
    
    /// - Tag: PlaceCharacter
    @IBAction func handleSceneTap(_ sender: UITapGestureRecognizer) {
        
        // Hit test to find a place for a virtual object.
        guard let hitTestResult = sceneView
            .hitTest(sender.location(in: sceneView), types: [.existingPlaneUsingGeometry, .estimatedHorizontalPlane])
            .first
            else { return }
        
        // Place an anchor for a virtual character. The model appears in renderer(_:didAdd:for:).
        let anchor = ARAnchor(name: "panda", transform: hitTestResult.worldTransform)
        sceneView.session.add(anchor: anchor)
    }
    
    // MARK: - AR session management
    private func loadRedPandaModel() -> SCNNode {
        let sceneURL = Bundle.main.url(forResource: "Sphere", withExtension: "scn", subdirectory: "art.scnassets")!
        let referenceNode = SCNReferenceNode(url: sceneURL)!
        referenceNode.load()
        return referenceNode
    }
}

