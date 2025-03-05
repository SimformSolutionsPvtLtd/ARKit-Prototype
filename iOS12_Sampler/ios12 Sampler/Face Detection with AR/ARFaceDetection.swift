//
//  ARFaceDetection.swift
//  ios12 Sampler
//
//  Created by Dhruvil Vora on 01/05/24.
//  Copyright © 2024 Testing. All rights reserved.
//

import RealityKit
import Vision
import ARKit
// Comment

class ARFaceDetection: UIViewController {

    // MARK: IBOutlets
    @IBOutlet var arview: ARView!
    @IBOutlet weak var circleVw: UIView!
    @IBOutlet weak var modelCollectionView: UICollectionView!

    // MARK: Variables
    var timer: Timer?
    var modelWidth: Float = 0.0
    var deviceWidth: Float = 0.0
    var currentLoadedEntity: Entity!
    var parentAnchorEntity: AnchorEntity?
    var models: [String] = ["Neon", "Heart", "Star", "Swag", "Glasses", "Animoji", "Cyclops"]

    // MARK: ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        setupARConfiguration()
        setupCircleView()
        setUpCollectionView()
        loadModel(withModelIndex: 0)
    }

    private func setupARConfiguration() {
        let configuaration = ARFaceTrackingConfiguration()
        configuaration.isLightEstimationEnabled = true
        arview.session.run(configuaration, options: [.resetTracking, .removeExistingAnchors])
        arview.session.delegate = self
    }

    private func setupCircleView() {
        deviceWidth = Float(UIScreen.main.bounds.size.width) + 100
        circleVw.layer.cornerRadius = (circleVw.layer.frame.width / 2)
        circleVw.layer.borderWidth = 10
        circleVw.layer.borderColor = UIColor.green.cgColor
    }

    private func setUpCollectionView() {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: ((UIScreen.main.bounds.width) / 2) - 50,
                                           bottom: 0, right: ((UIScreen.main.bounds.width) / 2) - 50)
        layout.scrollDirection = .horizontal
        modelCollectionView.collectionViewLayout = layout
        modelCollectionView.delegate = self
        modelCollectionView.dataSource = self
        modelCollectionView.reloadData()
    }

    // Calculate the scaling of model using sertain params
    private func newCalculateScalingModel(modelWidth: Float) -> Float {
        // Convert Models width to points
        let modelWidthInPts = modelWidth.toPoints
        // Then need to divide device width with the converted width in points
        // to get the ratio
        let convertedRatio = deviceWidth/modelWidthInPts
        return convertedRatio
    }

    private func loadModel(withModelIndex index: Int) {
        // Need to remove existing model if any is placed in ARView
        parentAnchorEntity?.removeChild(currentLoadedEntity)
        // load the model
        let entity = try! ModelEntity.load(named: models[index])
        // Get the bounds of loaded model
        let entityBounds = entity.visualBounds(relativeTo: nil)
        // Get the width of model from bounding box of entity
        modelWidth = entityBounds.extents.x
        currentLoadedEntity = entity
        // Calculate and scale the model
        let scaledModelCalculation = newCalculateScalingModel(modelWidth: modelWidth)
        entity.setScale([scaledModelCalculation, scaledModelCalculation, scaledModelCalculation], relativeTo: nil)

        // create a AnchorEntity tracking face
        if let anchorEntity = parentAnchorEntity {
            parentAnchorEntity = anchorEntity
        } else {
            parentAnchorEntity = AnchorEntity(.face)
        }
        parentAnchorEntity?.addChild(entity)
        arview.scene.anchors.append(parentAnchorEntity!)
    }
}

// MARK: UIScrollViewDelegate
extension ARFaceDetection {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            stopScrolling(scrollView: scrollView)
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        stopScrolling(scrollView: scrollView)
    }

    private func stopScrolling(scrollView: UIScrollView) {
        let modularCount = (Float(scrollView.contentOffset.x) / 95)
        guard Int(round(modularCount)) <= models.count else { return }
        scrollAndLoadModel(with: Int(modularCount))
    }

    private func scrollAndLoadModel(with indexToScroll: Int) {
        modelCollectionView.scrollToItem(at: IndexPath(item: indexToScroll, section: 0), at: .centeredHorizontally, animated: true)
        loadModel(withModelIndex: indexToScroll)
    }
}

// MARK: ARSessionDelegate
extension ARFaceDetection: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            // Track anchor of Face only & For Animoji only
            guard let anchor = anchor as? ARFaceAnchor, currentLoadedEntity.findEntity(named: "Animoji") != nil else { continue }
            // Get Eyebrows and Jaws displacement value
            guard let browOuterUpLeftShape = anchor.blendShapes[.browOuterUpLeft]?.floatValue,
                  let browOuterUpRightShape = anchor.blendShapes[.browOuterUpRight]?.floatValue,
                  let jawShape = anchor.blendShapes[.jawOpen]?.floatValue else { continue }

            // Then find that particular entity from Animoji model
            guard let leftBrowEntity = currentLoadedEntity?.findEntity(named: "left_eyebrow"),
                  let rightBrowEntity = currentLoadedEntity?.findEntity(named: "right_eyebrow"),
                  let jawEntity = currentLoadedEntity?.findEntity(named: "jaw") else { continue }

            // Change the position of that entity realtime to reflect user's expression
            leftBrowEntity.position.y = 0.082 + (browOuterUpLeftShape / 10)
            rightBrowEntity.position.y = 0.082 + (browOuterUpRightShape / 10)
            jawEntity.position.y = -0.067 - (jawShape / 10)
        }
    }
}

// MARK: UICollectionViewDataSource
extension ARFaceDetection: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return models.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let collectionViewCell: ModelCollectionCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ModelCollectionCell", for: indexPath) as? ModelCollectionCell else { return UICollectionViewCell() }
        collectionViewCell.configureCell(indexPath: indexPath.item)
        return collectionViewCell
    }
}

// MARK: UICollectionViewDelegate
extension ARFaceDetection: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        scrollAndLoadModel(with: indexPath.item)
    }
}

// MARK: UICollectionViewDelegateFlowLayout
extension ARFaceDetection: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: 100, height: 100)
    }
}
