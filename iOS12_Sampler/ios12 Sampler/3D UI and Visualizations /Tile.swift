/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A visualization indicating when part of a scanned bounding box has enough data for recognition.
*/

import UIKit
import SceneKit

class Tile: SCNNode {
    
    var isCaptured: Bool = false
    var isHighlighted: Bool = false
    
    func updateVisualization() {
        var newOpacity: CGFloat = isCaptured ? 0.5 : 0.0
        newOpacity += isHighlighted ? 0.35 : 0.0
        opacity = newOpacity
    }
    
    init(_ plane: SCNPlane) {
        super.init()
        self.geometry = plane
        self.opacity = 0.0
        
        // Create a child node with another plane of the same size, but a darker color to stand out better.
        // This helps users see captured tiles from the back.
        if childNodes.isEmpty {
            let innerPlane = SCNPlane(width: plane.width, height: plane.height)
            innerPlane.materials = [SCNMaterial.material(withDiffuse: UIColor.appBrown.withAlphaComponent(0.8), isDoubleSided: false)]
            let innerNode = SCNNode(geometry: innerPlane)
            innerNode.simdEulerAngles = float3(0, .pi, 0)
            addChildNode(innerNode)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
