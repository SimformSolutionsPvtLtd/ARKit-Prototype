//
//  ARImageDetectorVC.swift
//  ios12 Sampler
//
//  Created by Dhruvil Vora on 20/12/23.
//  Copyright © 2023 Testing. All rights reserved.
//

import UIKit
import ARKit

// This screen will be loaded and will ask to track image
class ARImageDetectorVC: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var messagePanel: UIView!
    @IBOutlet weak var messageLabel: UILabel!

    /// need to create an instance as this class's sceneView Outlet will be accessible
    /// from the RectangleDetector class inorder to track an image
    static var instance: ARImageDetectorVC?

    /// Inorder to get tracked rectangle from user's live camera feed
    ///  we need to create an obj for RectangleDetector Class and self assign its delegate property
    let rectangleDetector = RectangleDetector()

    /// Need to have AReferenceImage which represents an augmented image
    /// that exists in the user's environment.
    var alteredImage: AlteredImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        rectangleDetector.rectangleDelegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ARImageDetectorVC.instance = self

        // Prevent the screen from being dimmed after a while.
        UIApplication.shared.isIdleTimerDisabled = true

        searchForNewImageToTrack()
    }

    private func searchForNewImageToTrack() {
        alteredImage = nil
        alteredImage?.delegate = nil

        runImageTrackingSession(with: [], runOption: [.removeExistingAnchors, .resetTracking])
    }

    private func runImageTrackingSession(with trackingImages: Set<ARReferenceImage>,
                                         runOption: ARSession.RunOptions = [.removeExistingAnchors]) {
        let configuration = ARImageTrackingConfiguration()
        configuration.trackingImages = trackingImages
        configuration.maximumNumberOfTrackedImages = 1
        sceneView.session.run(configuration, options: runOption)
    }

    // The timer for message presentation.
    private var messageHideTimer: Timer?

    func showMessage(_ message: String, autoHide: Bool = true) {
        DispatchQueue.main.async {
            self.messageLabel.text = message
            self.setMessageHidden(false)

            self.messageHideTimer?.invalidate()
            if autoHide {
                self.messageHideTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
                    self?.setMessageHidden(true)
                }
            }
        }
    }

    private func setMessageHidden(_ hide: Bool) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.25, delay: 0, options: [.beginFromCurrentState], animations: {
                self.messagePanel.alpha = hide ? 0 : 1
            })
        }
    }
}

extension ARImageDetectorVC: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        alteredImage?.add(node: node, anchor: anchor)
        setMessageHidden(true)
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        alteredImage?.update(anchor)
    }
}

extension ARImageDetectorVC: RectangleDetectorDelegate {
    func rectangleDetected(rectangleContent: CIImage) {
        /// Now as soon as the exact rectangle is available we need to now create a ARReference image for altering the image
        /// All things must be performed on main  thread

        DispatchQueue.main.async {

            // Ignore detected rectangles if the app is currently tracking an image.
            guard self.alteredImage == nil else {
                return
            }

            guard let referenceImagePixelBuffer = rectangleContent.toPixelBuffer(pixelFormat: kCVPixelFormatType_32BGRA) else {
                print("Error convertting to pixel buffer")
                return
            }
            let possibleReferenceImage = ARReferenceImage(referenceImagePixelBuffer, orientation: .up, physicalWidth: CGFloat(0.5))
            possibleReferenceImage.validate { [weak self] (error) in
                if let error = error {
                    print("Error creating ref image \(error.localizedDescription)")
                    return
                }
                guard let newAlteredImage = AlteredImage(image: rectangleContent, referenceImage: possibleReferenceImage) else { return }
                newAlteredImage.delegate = self
                self?.alteredImage = newAlteredImage

                self?.runImageTrackingSession(with: [newAlteredImage.refrenceImage])
            }
        }
    }
}

extension ARImageDetectorVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return getFilterData().count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let data = getFilterData()
        guard let cell: FilterCell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterCell", for: indexPath) as? FilterCell else {
            return UICollectionViewCell()
        }
        cell.configureUI(filterModel: data[indexPath.item], index: indexPath.item)
        cell.filterCellTapDelegate = self
        return cell
    }
}

extension ARImageDetectorVC: FilterCellTapDelegate {
    func filterCellTapped(index: Int) {
        guard let alterImage = alteredImage else { return }
        alterImage.selectPreferredStyle(index: index)
    }
}


extension ARImageDetectorVC: AlteredImageDelegate {
    func alteredImageLostTracking(_ alteredImage: AlteredImage) {
        searchForNewImageToTrack()
    }
}
