//
//  ARPostureDetection.swift
//  ios12 Sampler
//
//  Created by Dhruvil Vora on 28/02/24.
//  Copyright © 2024 Testing. All rights reserved.
//

import UIKit
import RealityKit
import ARKit
import Combine
import SwiftUI

class ARPostureDetection: UIViewController {

    @IBOutlet var arView: ARView!

    // The 3D character to display.
    var meshEntity: ModelEntity?
    var meshAnchor = AnchorEntity()
    var character: BodyTrackedEntity?

    let labelView: UILabel = {
        let label = UILabel()
        label.text = "Angle"
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        label.textColor = UIColor.green
        return label
    }()

    override func viewDidLoad() {
        loadLabel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        arView.session.delegate = self

        // If the iOS device doesn't support body tracking, raise a developer error for
        // this unhandled case.
        guard ARBodyTrackingConfiguration.isSupported else {
            fatalError("This feature is only supported on devices with an A12 chip")
        }

        // Run a body tracking configration.
        let configuration = ARBodyTrackingConfiguration()
        arView.session.run(configuration)
        self.arView.scene.addAnchor(meshAnchor)
    }

    private func loadLabel() {
        arView.addSubview(labelView)
        labelView.translatesAutoresizingMaskIntoConstraints = false
        labelView.bottomAnchor.constraint(equalTo: arView.bottomAnchor, constant: -20).isActive = true
        labelView.leadingAnchor.constraint(equalTo: arView.leadingAnchor, constant: 0).isActive = true
        labelView.trailingAnchor.constraint(equalTo: arView.trailingAnchor, constant: 0).isActive = true
        labelView.textAlignment = .center
    }
}

/// Used to Generate/Update mesh
extension ARPostureDetection {
    func updateSemiCircleMesh(forAngle: Double, modelEntity: ModelEntity?, isFacingLeft: Bool) {
        guard let entity = modelEntity,
                let mesh = MeshResource.createSemiCircleMeshForAngle(angle: Float(forAngle),
                                                                     isFacingLeft: isFacingLeft) else { return }
        entity.model?.materials[0] = SimpleMaterial(color: Int(forAngle).postureIntensityColor(),
                                                    isMetallic: false)
        entity.model?.mesh = mesh
    }

    func generateEntityFromMesh(mesh: MeshResource, angle: Int) -> ModelEntity {
        let material = SimpleMaterial(color: angle.postureIntensityColor(), isMetallic: false)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.setScale([0.35, 0.35, 0.35], relativeTo: nil)
        return entity
    }
}

