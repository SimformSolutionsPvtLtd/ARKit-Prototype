//
//  ImageTrackingUtility.swift
//  ios12 Sampler
//
//  Created by Dhruvil Vora on 04/01/24.
//  Copyright © 2024 Testing. All rights reserved.
//

import VideoToolbox
import CoreImage
import CoreML
import SceneKit

class FilterModel {
    var filterDummyImage: UIImage
    var filterName: String
    var isSelected: Bool
    var selectedFilterStyle: SelectedFilterStyle

    init(filterDummyImage: UIImage, filterName: String, isSelected: Bool, selectedFilterStyle: SelectedFilterStyle = .otherStyle) {
        self.filterDummyImage = filterDummyImage
        self.filterName = filterName
        self.isSelected = isSelected
        self.selectedFilterStyle = selectedFilterStyle
    }
}

enum SelectedFilterStyle {
    case randomStyle
    case otherStyle
}

extension CIImage {

    /// Returns a pixel buffer of the image's current contents.
    func toPixelBuffer(pixelFormat: OSType) -> CVPixelBuffer? {
        var buffer: CVPixelBuffer?
        let options = [
            kCVPixelBufferCGImageCompatibilityKey as String: NSNumber(value: true),
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: NSNumber(value: true)
        ]
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(extent.size.width),
                                         Int(extent.size.height),
                                         pixelFormat,
                                         options as CFDictionary, &buffer)

        if status == kCVReturnSuccess, let device = MTLCreateSystemDefaultDevice(), let pixelBuffer = buffer {
            let ciContext = CIContext(mtlDevice: device)
            ciContext.render(self, to: pixelBuffer)
        } else {
            print("Error: Converting CIImage to CVPixelBuffer failed.")
        }
        return buffer
    }

    func resizeImage(to size: CGSize) -> CIImage? {
        return self.transformed(by: CGAffineTransform(scaleX: size.width/extent.size.width
                                                      , y: size.height/extent.size.height))
    }
}

extension MLMultiArray {
    func setOnlyThisIndexToOne(index: Int) {
        print("Count :- ",count)
        guard index < count else {
            print("Invalid index passed")
            return
        }
        for index in 0..<count {
            self[index] = 0
        }
        self[index] = 1
    }
}

extension CVPixelBuffer {
    func toCGIImage() -> CGImage? {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(self, options: nil, imageOut: &cgImage)
        return cgImage
    }
}

func createPlaneNode(size: CGSize, rotation: Float, content: Any?) -> SCNNode {
    let plane = SCNPlane(width: size.width, height: size.height)
    plane.firstMaterial?.diffuse.contents = content
    let planeNode = SCNNode(geometry: plane)
    planeNode.eulerAngles.x = rotation
    return planeNode
}

func getFilterData() -> [FilterModel] {
    return [FilterModel(filterDummyImage: UIImage(named: "Random")!, filterName: "Random", isSelected: true, selectedFilterStyle: .randomStyle),
            FilterModel(filterDummyImage: UIImage(named: "style1")!, filterName: "Style1", isSelected: false),
            FilterModel(filterDummyImage: UIImage(named: "style2")!, filterName: "Style2", isSelected: false),
            FilterModel(filterDummyImage: UIImage(named: "style3")!, filterName: "Style3", isSelected: false),
            FilterModel(filterDummyImage: UIImage(named: "style4")!, filterName: "Style4", isSelected: false),
            FilterModel(filterDummyImage: UIImage(named: "style5")!, filterName: "Style5", isSelected: false),
            FilterModel(filterDummyImage: UIImage(named: "style6")!, filterName: "Style6", isSelected: false),
            FilterModel(filterDummyImage: UIImage(named: "style7")!, filterName: "Style7", isSelected: false),
            FilterModel(filterDummyImage: UIImage(named: "style8")!, filterName: "Style8", isSelected: false)]
}
