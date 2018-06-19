/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Visualizaitons and controls for resizing a bounding box.
*/

import Foundation
import SceneKit

class BoundingBoxSide: SCNNode {
    
    enum Position: CaseIterable {
        case front
        case back
        case left
        case right
        case bottom
        case top
    }
    
    // The bounding box face that is represented by this node.
    var face: Position
    
    // The normal vector of this side.
    var normal: float3 {
        switch face {
        case .front, .right, .top: return dragAxis.normal
        case .back, .left, .bottom: return -dragAxis.normal
        }
    }
    
    // The drag axis for this side.
    var dragAxis: Axis {
        switch face {
        case .left, .right: return Axis.x
        case .bottom, .top: return Axis.y
        case .front, .back: return Axis.z
        }
    }
    
    // The size of the entire side.
    private var size: CGSize = .zero
    
    // The tiles of this side.
    private(set) var tiles: [Tile] = []
    
    private var color = UIColor.appYellow
    
    // Maximum width or height of a tile. If the size of the side exceeds this value, a new row or column is added.
    private var maxTileSize: CGFloat = 0.1
    
    // Maximum number of tiles per row/column
    private var maxTileCount: Int = 4
    
    private(set) var isBusyUpdatingTiles: Bool = false
    
    // The size of the bounding box side when the tiles were updated the last time.
    private var sizeOnLastTileUpdate: CGSize = .zero
    
    // Whether the tiles need to be updated.
    private var tilesNeedUpdateForChangedSize: Bool {
        return sizeOnLastTileUpdate != size
    }
    
    private var xAxisExtNode = SCNNode()
    private var xAxisExtLines = [SCNNode]()
    private var yAxisExtNode = SCNNode()
    private var yAxisExtLines = [SCNNode]()
    private var zAxisExtNode = SCNNode()
    private var zAxisExtLines = [SCNNode]()
    
    // The completion if this side in range [0,1]
    var completion: Float {
        let capturedTiles = tiles.filter { $0.isCaptured }
        return Float(capturedTiles.count) / Float(tiles.count)
    }
    
    init(_ face: Position, boundingBoxExtent extent: float3, color: UIColor = .appYellow) {
        self.color = color
        self.face = face
        super.init()
        
        setup(boundingBoxExtent: extent)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup(boundingBoxExtent extent: float3) {
        self.size = size(from: extent)
        
        switch face {
        case .front:
            simdLocalTranslate(by: float3(0, 0, extent.z / 2))
        case .back:
            simdLocalTranslate(by: float3(0, 0, -extent.z / 2))
            simdLocalRotate(by: simd_quatf(angle: .pi, axis: .y))
        case .left:
            simdLocalTranslate(by: float3(-extent.x / 2, 0, 0))
            simdLocalRotate(by: simd_quatf(angle: -.pi / 2, axis: .y))
        case .right:
            simdLocalTranslate(by: float3(extent.x / 2, 0, 0))
            simdLocalRotate(by: simd_quatf(angle: .pi / 2, axis: .y))
        case .bottom:
            simdLocalTranslate(by: float3(0, -extent.y / 2, 0))
            simdLocalRotate(by: simd_quatf(angle: .pi / 2, axis: .x))
        case .top:
            simdLocalTranslate(by: float3(0, extent.y / 2, 0))
            simdLocalRotate(by: simd_quatf(angle: -.pi / 2, axis: .x))
        }
        
        setupExtensions()
    }
    
    func update(boundingBoxExtent extent: float3) {
        switch face {
        case .front:
            simdPosition = float3(0, 0, extent.z / 2)
        case .back:
            simdPosition = float3(0, 0, -extent.z / 2)
        case .left:
            simdPosition = float3(-extent.x / 2, 0, 0)
        case .right:
            simdPosition = float3(extent.x / 2, 0, 0)
        case .bottom:
            simdPosition = float3(0, -extent.y / 2, 0)
        case .top:
            simdPosition = float3(0, extent.y / 2, 0)
        }
        
        // Update extensions if the size has changed.
        let newSize = size(from: extent)
        if newSize != size {
            size = newSize
            updateExtensions()
        }
    }

    func updateVisualizationIfNeeded() {
        if !isBusyUpdatingTiles && tilesNeedUpdateForChangedSize {
            setupTiles()
        }
    }

    private func size(from extent: float3) -> CGSize {
        switch face {
        case .front, .back:
            return CGSize(width: CGFloat(extent.x), height: CGFloat(extent.y))
        case .left, .right:
            return CGSize(width: CGFloat(extent.z), height: CGFloat(extent.y))
        case .bottom, .top:
            return CGSize(width: CGFloat(extent.x), height: CGFloat(extent.z))
        }
    }

    // MARK: - Tile subdivision
    
    func setupTiles() {
        isBusyUpdatingTiles = true
        ScanObjectsVC.serialQueue.async {
        
            // Determine number of rows and colums
            let numRows = min(self.maxTileCount, Int(ceil(self.size.height / self.maxTileSize)))
            let numColumns = min(self.maxTileCount, Int(ceil(self.size.width / self.maxTileSize)))
            
            var newTiles = [Tile]()
            
            // Create updated tiles and lay them out
            for row in 0..<numRows {
                for col in 0..<numColumns {
                    let plane = SCNPlane(width: self.size.width / CGFloat(numColumns), height: self.size.height / CGFloat(numRows))
                    plane.materials = [SCNMaterial.material(withDiffuse: self.color, isDoubleSided: false)]

                    let xPos = -self.size.width / 2 + plane.width / 2 + CGFloat(col) * plane.width
                    let yPos = self.size.height / 2 - plane.height / 2 - CGFloat(row) * plane.height
                    
                    let tileNode = Tile(plane)
                    tileNode.simdPosition = float3(Float(xPos), Float(yPos), 0)
                    newTiles.append(tileNode)
                }
            }
            
            // Replace the nodes in the scene graph.
            self.tiles.forEach { $0.removeFromParentNode() }
            newTiles.forEach { self.addChildNode($0) }
            self.tiles = newTiles

            self.sizeOnLastTileUpdate = self.size
            self.isBusyUpdatingTiles = false
        }
    }
    
    // MARK: - Line-based dragging visualization
    
    func setupExtensions() {
        for index in 0...11 {
            let line = SCNNode()
            line.geometry = cylinder(width: 0.002, height: 0.1)
            if index < 4 {
                xAxisExtLines.append(line)
                line.simdLocalRotate(by: simd_quatf(angle: -.pi / 2, axis: .z))
                xAxisExtNode.addChildNode(line)
            } else if index < 8 {
                yAxisExtLines.append(line)
                yAxisExtNode.addChildNode(line)
            } else {
                zAxisExtLines.append(line)
                line.simdLocalRotate(by: simd_quatf(angle: -.pi / 2, axis: .x))
                zAxisExtNode.addChildNode(line)
            }
        }
        
        updateExtensions()
        hideXAxisExtensions()
        hideYAxisExtensions()
        hideZAxisExtensions()
        
        self.addChildNode(xAxisExtNode)
        self.addChildNode(yAxisExtNode)
        self.addChildNode(zAxisExtNode)
    }
    
    func updateExtensions() {
        guard xAxisExtLines.count == 4, yAxisExtLines.count == 4, zAxisExtLines.count == 4 else { return }
        
        xAxisExtLines[0].simdPosition = float3(-Float(size.width) / 2, -Float(size.height) / 2, 0)
        yAxisExtLines[0].simdPosition = float3(-Float(size.width) / 2, -Float(size.height) / 2, 0)
        zAxisExtLines[0].simdPosition = float3(-Float(size.width) / 2, -Float(size.height) / 2, 0)
        xAxisExtLines[1].simdPosition = float3(-Float(size.width) / 2, Float(size.height) / 2, 0)
        yAxisExtLines[1].simdPosition = float3(-Float(size.width) / 2, Float(size.height) / 2, 0)
        zAxisExtLines[1].simdPosition = float3(-Float(size.width) / 2, Float(size.height) / 2, 0)
        xAxisExtLines[2].simdPosition = float3(Float(size.width) / 2, -Float(size.height) / 2, 0)
        yAxisExtLines[2].simdPosition = float3(Float(size.width) / 2, -Float(size.height) / 2, 0)
        zAxisExtLines[2].simdPosition = float3(Float(size.width) / 2, -Float(size.height) / 2, 0)
        xAxisExtLines[3].simdPosition = float3(Float(size.width) / 2, Float(size.height) / 2, 0)
        yAxisExtLines[3].simdPosition = float3(Float(size.width) / 2, Float(size.height) / 2, 0)
        zAxisExtLines[3].simdPosition = float3(Float(size.width) / 2, Float(size.height) / 2, 0)
    }
    
    func showXAxisExtensions() {
        xAxisExtNode.isHidden = false
    }
    
    func hideXAxisExtensions() {
        xAxisExtNode.isHidden = true
    }
    
    func showYAxisExtensions() {
        yAxisExtNode.isHidden = false
    }
    
    func hideYAxisExtensions() {
        yAxisExtNode.isHidden = true
    }
    
    func showZAxisExtensions() {
        zAxisExtNode.isHidden = false
    }
    
    func hideZAxisExtensions() {
        zAxisExtNode.isHidden = true
    }
    
    private func cylinder(width: CGFloat, height: Float) -> SCNGeometry {
        let cylinderGeometry = SCNCylinder(radius: width / 2, height: CGFloat(height))
        let gradientMaterial = SCNMaterial.material(withDiffuse: UIImage(named: "gradientyellow"))
        let clearMaterial = SCNMaterial.material(withDiffuse: UIColor.clear)
        cylinderGeometry.materials = [gradientMaterial, clearMaterial, clearMaterial]
        return cylinderGeometry
    }
}
