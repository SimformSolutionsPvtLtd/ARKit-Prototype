//
//  AVMainVC.swift
//  ios12 Sampler
//
//  Created by Testing on 14/06/18.
//  Copyright © 2018 Testing. All rights reserved.
//

import UIKit
import AVFoundation

class AVMainVC: BaseCameraVC {

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
    
    @IBAction func btnActionWorldSharing(_ sender: Any) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "ARImageDetectorVC") as? ARImageDetectorVC
        self.navigationController?.pushViewController(vc!, animated: true)
    }
    
    @IBAction func btnActionScanAndDetectObjects(_ sender: UIButton) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "AVChoiceVC") as? AVChoiceVC
        self.navigationController?.pushViewController(vc!, animated: true)
    }
    @IBAction func btnImageDetection(_ sender: UIButton) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "AVImageDetaction") as? AVImageDetaction
        self.navigationController?.pushViewController(vc!, animated: true)
    }
    @IBAction func btnEnvironmentTexturing(_ sender: UIButton) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "AVTextureEnvironment") as? AVTextureEnvironment
        self.navigationController?.pushViewController(vc!, animated: true)
    }

    @IBAction func btnMoreClicked(_ sender: UIButton) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "AVDetailsVC") as? AVDetailsVC
        self.navigationController?.pushViewController(vc!, animated: true)
    }
}
