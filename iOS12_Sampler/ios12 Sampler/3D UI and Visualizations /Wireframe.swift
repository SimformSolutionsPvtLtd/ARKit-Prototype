/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A visualization of the edges of a 3D box.
*/

import Foundation
import SceneKit

class Wireframe: SCNNode {
    
    private var lineThickness: CGFloat = 0.002
    
    private var lineNodes: [SCNNode] = []
    
    private var color = UIColor.appYellow
    
    var isHighlighted: Bool = false {
        didSet {
            if isHighlighted {
                childNodes.forEach {
                    $0.geometry?.materials = [SCNMaterial.material(withDiffuse: UIColor.red)]
                }
                
            } else {
                childNodes.forEach {
                    $0.geometry?.materials = [SCNMaterial.material(withDiffuse: color)]
                }
            }
        }
    }
    
    private var flashTimer: Timer?
    private var flashDuration = 0.1
    
    init(extent: float3, color: UIColor, scale: CGFloat = 1.0) {
        super.init()
        self.color = color
        self.lineThickness *= scale
        
        for _ in 1...12 {
            let line = SCNNode()
            lineNodes.append(line)
            self.addChildNode(line)
        }
        
        setup(extent: extent)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(flash),
                                               name: ObjectOrigin.movedOutsideBoxNotification,
                                               object: nil)
    }
    
    private func setup(extent: float3) {
        // Translate and rotate line nodes to the right transforms
        lineNodes[0].simdLocalTranslate(by: float3(0, -extent.y / 2, -extent.z / 2))
        lineNodes[0].simdLocalRotate(by: simd_quatf(angle: -.pi / 2, axis: .z))
        
        lineNodes[1].simdLocalTranslate(by: float3(-extent.x / 2, -extent.y / 2, 0))
        lineNodes[1].simdLocalRotate(by: simd_quatf(angle: -.pi / 2, axis: .x))
        
        lineNodes[2].simdLocalTranslate(by: float3(0, -extent.y / 2, extent.z / 2))
        lineNodes[2].simdLocalRotate(by: simd_quatf(angle: -.pi / 2, axis: .z))
        
        lineNodes[3].simdLocalTranslate(by: float3(extent.x / 2, -extent.y / 2, 0))
        lineNodes[3].simdLocalRotate(by: simd_quatf(angle: -.pi / 2, axis: .x))
        
        lineNodes[4].simdLocalTranslate(by: float3(-extent.x / 2, 0, -extent.z / 2))
        lineNodes[5].simdLocalTranslate(by: float3(-extent.x / 2, 0, extent.z / 2))
        lineNodes[6].simdLocalTranslate(by: float3(extent.x / 2, 0, -extent.z / 2))
        lineNodes[7].simdLocalTranslate(by: float3(extent.x / 2, 0, extent.z / 2))
        
        lineNodes[8].simdLocalTranslate(by: float3(0, extent.y / 2, -extent.z / 2))
        lineNodes[8].simdLocalRotate(by: simd_quatf(angle: -.pi / 2, axis: .z))
        
        lineNodes[9].simdLocalTranslate(by: float3(-extent.x / 2, extent.y / 2, 0))
        lineNodes[9].simdLocalRotate(by: simd_quatf(angle: -.pi / 2, axis: .x))
        
        lineNodes[10].simdLocalTranslate(by: float3(0, extent.y / 2, extent.z / 2))
        lineNodes[10].simdLocalRotate(by: simd_quatf(angle: -.pi / 2, axis: .z))
        
        lineNodes[11].simdLocalTranslate(by: float3(extent.x / 2, extent.y / 2, 0))
        lineNodes[11].simdLocalRotate(by: simd_quatf(angle: -.pi / 2, axis: .x))
        
        // Assign geometries
        lineNodes[0].geometry = cylinder(width: lineThickness, height: extent.x, color: color)
        lineNodes[1].geometry = cylinder(width: lineThickness, height: extent.z, color: color)
        lineNodes[2].geometry = cylinder(width: lineThickness, height: extent.x, color: color)
        lineNodes[3].geometry = cylinder(width: lineThickness, height: extent.z, color: color)
        
        lineNodes[4].geometry = cylinder(width: lineThickness, height: extent.y, color: color)
        lineNodes[5].geometry = cylinder(width: lineThickness, height: extent.y, color: color)
        lineNodes[6].geometry = cylinder(width: lineThickness, height: extent.y, color: color)
        lineNodes[7].geometry = cylinder(width: lineThickness, height: extent.y, color: color)
        
        lineNodes[8].geometry = cylinder(width: lineThickness, height: extent.x, color: color)
        lineNodes[9].geometry = cylinder(width: lineThickness, height: extent.z, color: color)
        lineNodes[10].geometry = cylinder(width: lineThickness, height: extent.x, color: color)
        lineNodes[11].geometry = cylinder(width: lineThickness, height: extent.z, color: color)
    }
    
    func update(extent: float3) {
        guard lineNodes.count == 12 else {
            return
        }
        
        // Translate and rotate line nodes to the right transforms
        lineNodes[0].simdPosition = float3(0, -extent.y / 2, -extent.z / 2)
        lineNodes[1].simdPosition = float3(-extent.x / 2, -extent.y / 2, 0)
        lineNodes[2].simdPosition = float3(0, -extent.y / 2, extent.z / 2)
        lineNodes[3].simdPosition = float3(extent.x / 2, -extent.y / 2, 0)
        
        lineNodes[4].simdPosition = float3(-extent.x / 2, 0, -extent.z / 2)
        lineNodes[5].simdPosition = float3(-extent.x / 2, 0, extent.z / 2)
        lineNodes[6].simdPosition = float3(extent.x / 2, 0, -extent.z / 2)
        lineNodes[7].simdPosition = float3(extent.x / 2, 0, extent.z / 2)
        
        lineNodes[8].simdPosition = float3(0, extent.y / 2, -extent.z / 2)
        lineNodes[9].simdPosition = float3(-extent.x / 2, extent.y / 2, 0)
        lineNodes[10].simdPosition = float3(0, extent.y / 2, extent.z / 2)
        lineNodes[11].simdPosition = float3(extent.x / 2, extent.y / 2, 0)
        
        // Update the lines's heights
        (lineNodes[0].geometry as? SCNCylinder)?.height = CGFloat(extent.x)
        (lineNodes[1].geometry as? SCNCylinder)?.height = CGFloat(extent.z)
        (lineNodes[2].geometry as? SCNCylinder)?.height = CGFloat(extent.x)
        (lineNodes[3].geometry as? SCNCylinder)?.height = CGFloat(extent.z)
        
        (lineNodes[4].geometry as? SCNCylinder)?.height = CGFloat(extent.y)
        (lineNodes[5].geometry as? SCNCylinder)?.height = CGFloat(extent.y)
        (lineNodes[6].geometry as? SCNCylinder)?.height = CGFloat(extent.y)
        (lineNodes[7].geometry as? SCNCylinder)?.height = CGFloat(extent.y)
        
        (lineNodes[8].geometry as? SCNCylinder)?.height = CGFloat(extent.x)
        (lineNodes[9].geometry as? SCNCylinder)?.height = CGFloat(extent.z)
        (lineNodes[10].geometry as? SCNCylinder)?.height = CGFloat(extent.x)
        (lineNodes[11].geometry as? SCNCylinder)?.height = CGFloat(extent.z)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func cylinder(width: CGFloat, height: Float, color: UIColor) -> SCNGeometry {
        let cylinderGeometry = SCNCylinder(radius: width / 2, height: CGFloat(height))
        cylinderGeometry.materials = [SCNMaterial.material(withDiffuse: color)]
        return cylinderGeometry
    }
    
    @objc
    func flash() {
        isHighlighted = true
        
        flashTimer?.invalidate()
        flashTimer = Timer.scheduledTimer(withTimeInterval: flashDuration, repeats: false) { _ in
            DispatchQueue.main.async {
                self.isHighlighted = false
            }
        }
    }
}
