/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A generalized interactive visualization of a 3D point cloud.
*/

import SceneKit

// This is a protocol that should be implemented by all point cloud classes (ScannedPointCloud, DetectedPointCloud).
protocol PointCloud {
    func createVisualization(for points: [float3], color: UIColor, size: CGFloat) -> SCNGeometry?
}

// All classes implementing the PointCloud protocol can benefit from this createVisualization implementation.
extension PointCloud {
    func createVisualization(for points: [float3], color: UIColor, size: CGFloat) -> SCNGeometry? {
        guard !points.isEmpty else { return nil }
        
        let stride = MemoryLayout<float3>.size
        let pointData = Data(bytes: points, count: stride * points.count)
        
        // Create geometry source
        let source = SCNGeometrySource(data: pointData,
                                       semantic: SCNGeometrySource.Semantic.vertex,
                                       vectorCount: points.count,
                                       usesFloatComponents: true,
                                       componentsPerVector: 3,
                                       bytesPerComponent: MemoryLayout<Float>.size,
                                       dataOffset: 0,
                                       dataStride: stride)
        
        // Create geometry element
        let element = SCNGeometryElement(data: nil, primitiveType: .point, primitiveCount: points.count, bytesPerIndex: 0)
        element.pointSize = 0.001
        element.minimumPointScreenSpaceRadius = size
        element.maximumPointScreenSpaceRadius = size
        
        let pointsGeometry = SCNGeometry(sources: [source], elements: [element])
        pointsGeometry.materials = [SCNMaterial.material(withDiffuse: color)]
        
        return pointsGeometry
    }
}
