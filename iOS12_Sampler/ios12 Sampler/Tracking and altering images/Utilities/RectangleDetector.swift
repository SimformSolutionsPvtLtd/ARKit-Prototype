//
//  RectangleDetector.swift
//  ios12 Sampler
//
//  Created by Dhruvil Vora on 20/12/23.
//  Copyright © 2023 Testing. All rights reserved.
//

import UIKit
import Vision
import CoreImage

protocol RectangleDetectorDelegate: AnyObject {
    func rectangleDetected(rectangleContent: CIImage)
}

class RectangleDetector {

    private var currentCameraImage : CVPixelBuffer!
    private var updateTimer: Timer?

    private var updateInterval: Float = 0.1
    private var isBusy = false

    weak var rectangleDelegate: RectangleDetectorDelegate?

    init() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(updateInterval), repeats: true, 
                                           block: { [weak self] _ in
            if let captureImage = ARImageDetectorVC.instance?.sceneView.session.currentFrame?.capturedImage {
                self?.searchRectangle(in: captureImage)
            }
        })
    }

    private func searchRectangle(in pixelBuffer: CVPixelBuffer) {
        guard !isBusy else { return }
        isBusy = true

        // We need to remember the current image
        currentCameraImage = pixelBuffer

        // Note that the pixel buffer's orientation doesn't change even when the device rotates.
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)

        // Create a Vision rectangle detection request for running on the GPU.
        let request = VNDetectRectanglesRequest { request, error in
            // As soon as rectangle is found we get its dimension and apply filter on it to crop an image
            self.completedVisionRequest(request: request, error: error)
        }

        request.maximumObservations = 1
        request.minimumSize = 0.25
        request.minimumConfidence = 0.9
        request.minimumAspectRatio = 0.3
        request.quadratureTolerance = 20

        request.usesCPUOnly = false

        DispatchQueue.global().async {
            do {
                try handler.perform([request])
            } catch {
                print("Error: Rectangle detection failed - vision request failed.")
                self.isBusy = false
            }
        }
    }

    private func completedVisionRequest(request: VNRequest?, error: Error?) {
        defer {
            isBusy = false
        }
        // FIRST WE NEED TO CHECK WHETHER THE IMAGE 
        // WHICH WAS DETECTED IS RECTANGULAR ONE
        guard let rectangle = request?.results?.first as? VNRectangleObservation else {
            guard let error = error else { return }
            print("Error: Rectangle detection failed - Vision request returned an error. \(error.localizedDescription)")
            return
        }
        
        // So as soon as we get the rectangle we can use this and set the bounding points of the actual image

        // First we need to get actaul images size to use this as a reference and calulate the cropped image location(i.e point)
        let currentActualImageWidth = CGFloat( CVPixelBufferGetWidth(currentCameraImage) )
        let currentActualImageheight = CGFloat( CVPixelBufferGetHeight(currentCameraImage) )

        // Now we have to define the 4 bounding points for cropped(Actual) image
        let topLeft = CGPoint(x: rectangle.topLeft.x * currentActualImageWidth, y: rectangle.topLeft.y * currentActualImageheight)
        let topRight = CGPoint(x: rectangle.topRight.x * currentActualImageWidth, y: rectangle.topRight.y * currentActualImageheight)
        let bottomLeft = CGPoint(x: rectangle.bottomLeft.x * currentActualImageWidth, y: rectangle.bottomLeft.y * currentActualImageheight)
        let bottomRight = CGPoint(x: rectangle.bottomRight.x * currentActualImageWidth, y: rectangle.bottomRight.y * currentActualImageheight)

        // Create a filter that will create an image from new bounding points
        guard let filter = CIFilter(name: "CIPerspectiveCorrection") else {
            print("Error: Rectangle detection failed - Could not create perspective correction filter.")
            return
        }

        // Set the new value for specific key
        filter.setValue(CIVector(cgPoint: topLeft), forKey: "inputTopLeft")
        filter.setValue(CIVector(cgPoint: topRight), forKey: "inputTopRight")
        filter.setValue(CIVector(cgPoint: bottomLeft), forKey: "inputBottomLeft")
        filter.setValue(CIVector(cgPoint: bottomRight), forKey: "inputBottomRight")

        // Then apply this filter to the very first image we have captured
        let ciImage = CIImage(cvPixelBuffer: currentCameraImage).oriented(.up)
        filter.setValue(ciImage, forKey: kCIInputImageKey)

        // Which will now return a new(cropped) image
        guard let perspectiveImage = filter.value(forKey: kCIOutputImageKey) as? CIImage else {
            print("Error: Rectangle detection failed - perspective correction filter has no output image.")
            return
        }
        rectangleDelegate?.rectangleDetected(rectangleContent: perspectiveImage)
    }
}
