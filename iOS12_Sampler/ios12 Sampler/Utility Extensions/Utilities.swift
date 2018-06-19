/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Convenience extensions on system types used in this project.
*/

import Foundation
import ARKit

// Convenience accessors for Asset Catalog named colors.
extension UIColor {
    static let appYellow = UIColor(named: "appYellow")!
    static let appBrown = UIColor(named: "appBrown")!
    static let appGreen = UIColor(named: "appGreen")!
    static let appBlue = UIColor(named: "appBlue")!
    static let appLightBlue = UIColor(named: "appLightBlue")!
    static let appGray = UIColor(named: "appGray")!
}

enum Axis {
    case x
    case y
    case z
    
    var normal: float3 {
        switch self {
        case .x:
            return float3(1, 0, 0)
        case .y:
            return float3(0, 1, 0)
        case .z:
            return float3(0, 0, 1)
        }
    }
}

struct PlaneDrag {
    var planeTransform: float4x4
    var offset: float3
}

extension simd_quatf {
    init(angle: Float, axis: Axis) {
        self.init(angle: angle, axis: axis.normal)
    }
}

extension float4x4 {
    var position: float3 {
        return columns.3.xyz
    }
}

extension float4 {
    var xyz: float3 {
        return float3(x, y, z)
    }

    init(_ xyz: float3, _ w: Float) {
        self.init(xyz.x, xyz.y, xyz.z, w)
    }
}

extension SCNMaterial {
    
    static func material(withDiffuse diffuse: Any?, respondsToLighting: Bool = false, isDoubleSided: Bool = true) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = diffuse
        material.isDoubleSided = isDoubleSided
        if respondsToLighting {
            material.locksAmbientWithDiffuse = true
        } else {
            material.locksAmbientWithDiffuse = false
            material.ambient.contents = UIColor.black
            material.lightingModel = .constant
        }
        return material
    }
}

struct Ray {
    let origin: float3
    let direction: float3
    
    init(origin: float3, direction: float3) {
        self.origin = origin
        self.direction = direction
    }
    
    init(from pointOfView: SCNNode, length: Float) {
        let cameraNormal = normalize(pointOfView.simdWorldFront) * length
        self.origin = pointOfView.simdWorldPosition
        self.direction = cameraNormal
    }
}

extension ARSCNView {
    func unprojectPointLocal(_ point: CGPoint, ontoPlane planeTransform: float4x4) -> float3? {
        guard let result = unprojectPoint(point, ontoPlane: planeTransform) else {
            return nil
        }
        
        // Convert the result into the plane's local coordinate system.
        let point = float4(result, 1)
        let localResult = planeTransform.inverse * point
        return localResult.xyz
    }
    
    func smartHitTest(_ point: CGPoint) -> ARHitTestResult? {
        let hitTestResults = hitTest(point, types: .featurePoint)
        guard !hitTestResults.isEmpty else { return nil }
        
        for result in hitTestResults {
            // Return the first result which is between 20 cm and 3 m away from the user.
            if result.distance > 0.2 && result.distance < 3 {
                return result
            }
        }
        return nil
    }
}

extension SCNNode {
    
    /// Wrapper for SceneKit function to use SIMD vectors and a typed dictionary.
    open func hitTestWithSegment(from pointA: float3, to pointB: float3, options: [SCNHitTestOption: Any]? = nil) -> [SCNHitTestResult] {
        if let options = options {
            var rawOptions = [String: Any]()
            for (key, value) in options {
                switch (key, value) {
                case (_, let bool as Bool):
                    rawOptions[key.rawValue] = NSNumber(value: bool)
                case (.searchMode, let searchMode as SCNHitTestSearchMode):
                    rawOptions[key.rawValue] = NSNumber(value: searchMode.rawValue)
                case (.rootNode, let object as AnyObject):
                    rawOptions[key.rawValue] = object
                default:
                    fatalError("unexpected key/value in SCNHitTestOption dictionary")
                }
            }
            return hitTestWithSegment(from: SCNVector3(pointA), to: SCNVector3(pointB), options: rawOptions)
        } else {
            return hitTestWithSegment(from: SCNVector3(pointA), to: SCNVector3(pointB))
        }
    }
    
    func load3DModel(from url: URL) -> SCNNode? {
        guard let scene = try? SCNScene(url: url, options: nil) else {
            print("Error: Failed to load 3D model from file \(url)")
            return nil
        }
        
        let node = SCNNode()
        for child in scene.rootNode.childNodes {
            node.addChildNode(child)
        }
        
        // If there are no light sources in the model, add some
        let lightNodes = node.childNodes(passingTest: { node, _ in
            return node.light != nil
        })
        if lightNodes.isEmpty {
            let ambientLight = SCNLight()
            ambientLight.type = .ambient
            ambientLight.intensity = 100
            let ambientLightNode = SCNNode()
            ambientLightNode.light = ambientLight
            node.addChildNode(ambientLightNode)
            
            let directionalLight = SCNLight()
            directionalLight.type = .directional
            directionalLight.intensity = 500
            let directionalLightNode = SCNNode()
            directionalLightNode.light = directionalLight
            node.addChildNode(directionalLightNode)
        }
        
        return node
    }
}

extension CGPoint {
    /// Returns the length of a point when considered as a vector. (Used with gesture recognizers.)
    var length: CGFloat {
        return sqrt(x * x + y * y)
    }
}

func dragPlaneTransform(for dragRay: Ray, cameraPos: float3) -> float4x4 {
    
    let camToRayOrigin = normalize(dragRay.origin - cameraPos)
    
    // Create a transform for a XZ-plane. This transform can be passed to unproject() to
    // map the user's touch position in screen space onto that plane in 3D space.
    // The plane's transform is constructed such that:
    // 1. The ray along which we want to drag the object is the plane's X axis.
    // 2. The plane's Z axis is ortogonal to the X axis and orthogonal to the vector
    //    from the camera to the object.
    //
    // Defining the plane this way has two main benefits:
    // 1. Since we want to drag the object along an axis (not on a plane), we need to
    //    do one more projection from the plane's 2D space to a 1D axis. Since the axis to
    //    drag on is the plane's X-axis, we can later simply convert the un-projected point
    //    into the plane's local coordinate system and use the value on the X axis.
    // 2. The plane's Z-axis is chosen to maximize the plane's coverage of screen space.
    //    The unprojectPoint() method will stop returning positions if the user drags their
    //    finger on the screen across the plane's horizon, leading to a bad user experience.
    //    So the ideal plane is parallel or almost parallel to the screen, but this is not
    //    possible when dragging along an axis which is pointing at the camera. For that case
    //    we try to find a plane which covers as much screen space as possible.
    let xVector = dragRay.direction
    let zVector = normalize(cross(xVector, camToRayOrigin))
    let yVector = normalize(cross(xVector, zVector))
    
    return float4x4([float4(xVector, 0),
                     float4(yVector, 0),
                     float4(zVector, 0),
                     float4(dragRay.origin, 1)])
}
