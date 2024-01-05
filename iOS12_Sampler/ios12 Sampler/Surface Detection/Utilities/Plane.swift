//
//  Plane.swift
//  ios12 Sampler
//
//  Created by Dhruvil Vora on 18/12/23.
//  Copyright © 2023 Testing. All rights reserved.
//

import ARKit

class Plane: SCNNode {

    var meshNode: SCNNode
    var extentNode: SCNNode
    var classificationNode: SCNNode?

    init(anchor: ARPlaneAnchor, in sceneView: ARSCNView) {

        #if targetEnvironment(simulator)
        #error("ARKit is not supported in iOS Simulator. Connect a physical iOS device and select it as your Xcode run destination, or select Generic iOS Device as a build-only destination.")
        #else

        // Create a plane geometry and assign it to a new node
        // This helps in visualizing the estimated shape of the plane
        guard let meshGeometry = ARSCNPlaneGeometry(device: sceneView.device!)
            else { fatalError("Can't create Geometry") }
        meshGeometry.update(from: anchor.geometry)
        meshNode = SCNNode(geometry: meshGeometry)

        // This geomentry helps us to visualize plane's bounding rectangle
        if #available(iOS 16.0, *) {
            let extentPlane = SCNPlane(width: CGFloat(anchor.planeExtent.width), height: CGFloat(anchor.planeExtent.height))
            extentNode = SCNNode(geometry: extentPlane)
            extentNode.simdPosition = anchor.center
        } else {
            let extentPlane = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
            extentNode = SCNNode(geometry: extentPlane)
            extentNode.simdPosition = anchor.center
        }

        // `SCNPlane` is vertically oriented in its local coordinate space, so
        // rotate it to match the orientation of `ARPlaneAnchor`.
        extentNode.eulerAngles.x = -.pi / 2

        super.init()

        self.setupMeshVisualStyles()
        self.setupExtentVisualStyles()

        // Add both the nodes as the plane's child node
        addChildNode(meshNode)
        addChildNode(extentNode)

        if #available(iOS 12.0, *), ARPlaneAnchor.isClassificationSupported {
            let textNode = makeTextNode(anchor.classification.description)
            classificationNode = textNode
            textNode.centerAlign()
            extentNode.addChildNode(textNode)
        }

        #endif
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupMeshVisualStyles() {
        meshNode.opacity = 0.25
        guard let material = meshNode.geometry?.firstMaterial else { return }
        material.diffuse.contents = UIColor.appYellow
    }

    private func setupExtentVisualStyles() {
        // Make the extent visualization semitransparent to clearly show real-world placement.
        extentNode.opacity = 0.6

        guard let material = extentNode.geometry?.firstMaterial
            else { fatalError("SCNPlane always has one material") }

        material.diffuse.contents = UIColor.appYellow

        guard let shaderFilePath = Bundle.main.path(forResource: "wireframe_shader", ofType: "metal", inDirectory: "art.scnassets") 
                else { return }
        do {
            let shaderString = try String(contentsOfFile: shaderFilePath, encoding: .utf8)
            material.shaderModifiers = [.surface: shaderString]
        }
        catch {
            fatalError("Can't load wireframe shader: \(error)")
        }
    }

    private func makeTextNode(_ text: String) -> SCNNode {
        let textGeometry = SCNText(string: text, extrusionDepth: 1)
        textGeometry.font = UIFont(name: "Futura", size: 50)

        let textNode = SCNNode(geometry: textGeometry)
        textNode.simdScale = float3(0.005)
        return textNode
    }
}
