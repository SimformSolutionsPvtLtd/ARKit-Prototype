//
//  VisuallizationNode.swift
//  ios12 Sampler
//
//  Created by Dhruvil Vora on 05/01/24.
//  Copyright © 2024 Testing. All rights reserved.
//

import Foundation
import SceneKit

protocol VisualizationNodeDelegate: AnyObject {
    func animationDidFinish()
}

/// This class is especially used to show the altered image with some animation
class VisuallizationNode: SCNNode {
    
    /// If we have to create a fade animation between 2 images
    let previousImage: SCNNode
    let currentImage: SCNNode

    weak var delegate: VisualizationNodeDelegate?
    /**
     Create a plane geometry for the current and previous altered images sized to the argument
     size, and initialize them with transparent material.
     Because `SCNPlane` is defined in the XY-plane,
     but `ARImageAnchor` is defined in the XZ plane, you rotate by 90 degrees to match.
     */
    init(size: CGSize) {
        previousImage = createPlaneNode(size: size, rotation: -.pi/2, content: UIColor.green)
        currentImage = createPlaneNode(size: size, rotation: -.pi/2, content: UIColor.red)
        super.init()

        addChildNode(previousImage)
        addChildNode(currentImage)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func display(alteredImage: CVPixelBuffer) {
        /// First we need to apply all he contents of the current image to theprevious image
        /// Then we can assign newly altered image to currentImage
        previousImage.geometry?.firstMaterial?.diffuse.contents = currentImage.geometry?.firstMaterial?.diffuse.contents
        currentImage.geometry?.firstMaterial?.diffuse.contents = alteredImage.toCGIImage()

        /// Then we need to reduce the opacity for the curent image
        /// so previous image is visible
        previousImage.opacity = 1.0
        currentImage.opacity = 0.0

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1
        /// Then after starting the animation we can show new image
        previousImage.opacity = 0.0
        currentImage.opacity = 1.0
        SCNTransaction.completionBlock = { [weak self] in
            guard let self else { return }
            // Need to call finish animation delegate method inorder to
            self.delegate?.animationDidFinish()
        }
        SCNTransaction.commit()
    }
}
