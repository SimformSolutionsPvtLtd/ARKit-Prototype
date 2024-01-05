//
//  AlteredImage.swift
//  ios12 Sampler
//
//  Created by Dhruvil Vora on 04/01/24.
//  Copyright © 2024 Testing. All rights reserved.
//

import Foundation
import ARKit
import CoreML

/**
 Tells a delegate when image tracking failed.
 */
protocol AlteredImageDelegate: AnyObject {
    func alteredImageLostTracking(_ alteredImage: AlteredImage)
}

class AlteredImage {

    /// Which holds our reference Images
    var refrenceImage: ARReferenceImage

    /// A handle to the anchor ARKit assigned the tracked image.
    private var anchor: ARImageAnchor?

    /// A SceneKit node that animates images of varying style.
    private let visualizationNode: VisuallizationNode

    /// Stores a reference of output image given by core ml model
    private var modelOutputImage: CVPixelBuffer?

    /// Bool to inidcate whether fade animation is enabled
    private let fadeAnimation = true

    /// A timer that effects a grace period before checking
    ///  for a new rectangular shape in the user's environment.
    private var failedTrackingTimeout: Timer?

    /// The timeout in seconds after which the `imageTrackingLost` delegate is called.
    private var timeout: TimeInterval = 1.0

    private var fadeBetweenImages = true

    /**
     The ML model to be used for the image alteration. For this class to compile, the model
     has to accept an input image called `image` and a style index called `index`.
     Note that this is static in order to avoid spikes in memory usage when replacing
     instances of the `AlteredImage` class.
     */
    private static var styleTransferModel: StyleTransferModel = {
        do {
            let configuration = MLModelConfiguration()
            return try StyleTransferModel(configuration: configuration)
        } catch {
            fatalError("Couldn't create StyleTransferModel due to: \(error)")
        }
    }()

    /// The input parameters to the Core ML model.
    private var modelInputImage: CVPixelBuffer

    private var styleIndexArray: MLMultiArray

    private var numberOfStyles = 1

    /// The index of the current image's style.
    private var styleIndex = 0

    /// A delegate to tell when image tracking fails.
    weak var delegate: AlteredImageDelegate?

    init?(image: CIImage, referenceImage: ARReferenceImage) {
        /// Most importantly we now have to fetch the requirement for input image which we have to supply to the MLModel
        /// Also we know that we need to provide our actual image and MLMultiArray to alter an image according to the selected style
        /// In short we currently don't have any info about what input data MLModel needs to process an image,
        /// So first we need to retrive info from the MLModel itself about its required parameter input
        /// So inorder to retrieve the required dimension which MLModel need inorder to alter an image we need to do the following

        /// for input image
        var modelInputImageSize: CGSize? = nil
        var modelInputImageFormat: OSType = 0
        /// for input MLMultiArray array
        var styleIndexArrayShape: [NSNumber] = []
        var styleIndexArrayFormat: MLMultiArrayDataType = .double

        /// Now need to retrieve info from our MlModel(i.e. StyleTransferModel)
        for inputDescription in AlteredImage.styleTransferModel.model.modelDescription.inputDescriptionsByName {
            let featureDescription = inputDescription.value

            if featureDescription.type == .image {
                guard let imageConstraint = featureDescription.imageConstraint else {
                    fatalError("Assumption: `imageConstraint` should never be nil for feature descriptions of type `image`.")
                }
                /// This are the required dimensions which MLModel needs as an input
                modelInputImageSize = CGSize(width: imageConstraint.pixelsWide, height: imageConstraint.pixelsHigh)
                modelInputImageFormat = imageConstraint.pixelFormatType
            } else if featureDescription.type == .multiArray {
                guard let multiArrayConstraint = featureDescription.multiArrayConstraint else {
                    fatalError("Assumption: `multiArrayConstraint` should never be nil for feature descriptions of type `multiArray`.")
                }
                /// This are the required data for multiarray which MLModel needs as an input
                styleIndexArrayShape = multiArrayConstraint.shape
                styleIndexArrayFormat = multiArrayConstraint.dataType
                if multiArrayConstraint.shape.count == 1 {
                    numberOfStyles = multiArrayConstraint.shape[0].intValue
                }
            }
        }

        /// Lets create a required multiArray
        do {
            styleIndexArray = try MLMultiArray(shape: styleIndexArrayShape, dataType: styleIndexArrayFormat)
        } catch {
            print("Error: Could not create altered image input array.")
            return nil
        }

        /// lets create an image from the required dimension returned from the MLModel
        guard let modelImageSize = modelInputImageSize,
              let resizedImage = image.resizeImage(to: modelImageSize),
              let resizedPixelBuffer = resizedImage.toPixelBuffer(pixelFormat: modelInputImageFormat) else {
            print("Error: Could not convert input image to the model's expected format.")
            return nil
        }
        modelInputImage = resizedPixelBuffer
        self.refrenceImage = referenceImage

        visualizationNode = VisuallizationNode(size: referenceImage.physicalSize)
        visualizationNode.delegate = self

        createAlteredImage()
    }

    func createAlteredImage() {
        /// Set the specific index to one (i.e set the index to one for the style we have to apply)
        print("self.styleIndexArray :-" ,self.styleIndexArray)
        self.styleIndexArray.setOnlyThisIndexToOne(index: styleIndex)
        print("self.styleIndexArray New :-" ,self.styleIndexArray)

        let options = MLPredictionOptions()
        options.usesCPUOnly = false
        let input = StyleTransferModelInput(image: modelInputImage, index: styleIndexArray)
        do {
            let output = try AlteredImage.styleTransferModel.prediction(input: input, options: options)
            imageAlteringComplete(alteredImage: output.stylizedImage)
        } catch(let error) {
            print("Error in altering image \(error.localizedDescription)")
        }
    }

    private func selectNextStyle() {
        print("StyleIndex old :- ", styleIndex)
        guard styleIndex < numberOfStyles - 1 else {
            styleIndex = 0
            print("StyleIndex new :- ", styleIndex)
            return
        }
        styleIndex += 1
        print("StyleIndex new :- ", styleIndex)
    }

    func selectPreferredStyle(index: Int) {
        guard fadeBetweenImages, anchor != nil else { return }
        styleIndexArray.setOnlyThisIndexToOne(index: index)
        createAlteredImage()
    }

    /// Displays the altered image using the anchor and node provided by ARKit.
    /// - Tag: AddVisualizationNode
    func add(node: SCNNode, anchor: ARAnchor) {
        if let imageAnchor = anchor as? ARImageAnchor, imageAnchor.referenceImage == refrenceImage {
            self.anchor = imageAnchor

            // Add the node that displays the altered image to the node graph.
            node.addChildNode(visualizationNode)

            // If altering the first image completed before the
            //  anchor was added, display that image now.
            if let createdImage = modelOutputImage {
                visualizationNode.display(alteredImage: createdImage)
            }
        }
    }

    /**
     If an image the app was tracking is no longer tracked for a given amount of time, invalidate
     the current image tracking session. This, in turn, enables Vision to start looking for a new
     rectangular shape in the camera feed.
     - Tag: AnchorWasUpdated
     */
    func update(_ anchor: ARAnchor) {
        if let imageAnchor = anchor as? ARImageAnchor, self.anchor == anchor {
            self.anchor = imageAnchor
            // Reset the timeout if the app is still tracking an image.
            if imageAnchor.isTracked {
//                resetImageTrackingTimeout()
            }
        }
    }

    func imageAlteringComplete(alteredImage: CVPixelBuffer) {
        modelOutputImage = alteredImage
        visualizationNode.display(alteredImage: alteredImage)
    }

    /// If altering the image failed, notify delegate the
    ///  to stop tracking this image.
    func imageAlteringFailed(_ errorDescription: String) {
        print("Error: Altering image failed - \(errorDescription).")
        self.delegate?.alteredImageLostTracking(self)
    }
}

extension AlteredImage: VisualizationNodeDelegate {
    func animationDidFinish() {
        guard fadeBetweenImages, anchor != nil else { return }
        selectNextStyle()
        createAlteredImage()
    }
}
