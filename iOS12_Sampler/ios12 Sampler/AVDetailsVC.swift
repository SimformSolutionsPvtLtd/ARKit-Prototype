//
//  AVDetailsVC.swift
//  ios12 Sampler
//
//  Created by Dhruvil Vora on 29/02/24.
//  Copyright © 2024 Testing. All rights reserved.
//

import UIKit

class AVDetailsVC: BaseCameraVC {

    @IBOutlet weak var cameraView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        cameraView.layer.addSublayer(prevLayer!)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    @IBAction func btnLiveImageFilterClicked(_ sender: UIButton) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "ARImageDetectorVC") as? ARImageDetectorVC
        self.navigationController?.pushViewController(vc!, animated: true)
    }

    @IBAction func btnSurfaceDetectionClicked(_ sender: UIButton) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "ARFaceDetection") as? ARFaceDetection
        self.navigationController?.pushViewController(vc!, animated: true)
    }

    @IBAction func btnSittingPostureClicked(_ sender: UIButton) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "ARPostureDetection") as? ARPostureDetection
        self.navigationController?.pushViewController(vc!, animated: true)
    }

    @IBAction func btnStandingPostureClicked(_ sender: UIButton) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "StandingPostureVC") as? StandingPostureVC
        self.navigationController?.pushViewController(vc!, animated: true)
    }
}
