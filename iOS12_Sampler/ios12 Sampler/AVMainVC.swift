//
//  AVMainVC.swift
//  ios12 Sampler
//
//  Created by Testing on 14/06/18.
//  Copyright © 2018 Testing. All rights reserved.
//

import UIKit
import AVFoundation

class AVMainVC: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    var session: AVCaptureSession?
    var device: AVCaptureDevice?
    var input: AVCaptureDeviceInput?
    var output: AVCaptureMetadataOutput?
    var prevLayer: AVCaptureVideoPreviewLayer?
    
    @IBOutlet weak var CameraView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createSession()
        // Do any additional setup after loading the view.
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }
    
    @IBAction func btnActionWorldSharing(_ sender: Any) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "ARImageDetectorVC") as? ARImageDetectorVC
        self.navigationController?.pushViewController(vc!, animated: true)
//        let vc = self.storyboard?.instantiateViewController(withIdentifier: "ARSurfaceDetectionVC") as? ARSurfaceDetectionVC
//        self.navigationController?.pushViewController(vc!, animated: true)
//        let vc = self.storyboard?.instantiateViewController(withIdentifier: "AVSharingWorldMapVC") as? AVSharingWorldMapVC
//        self.navigationController?.pushViewController(vc!, animated: true)
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
    func createSession() {
        session = AVCaptureSession()
        device = AVCaptureDevice.default(for: .video)
        
        var error: NSError? = nil
        do {
            if device != nil {
                input = try AVCaptureDeviceInput(device: device!)
            }
        } catch  {
            print(error)
        }
        
        if error == nil {
            if input != nil {
                session?.addInput(input!)
            }
        } else {
            print("camera input error: \(String(describing: error))")
        }
        
        prevLayer = AVCaptureVideoPreviewLayer(session: session!)
        let del = UIApplication.shared.delegate as? AppDelegate
        prevLayer?.frame = (del?.window?.frame)!
        prevLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        CameraView.layer.addSublayer(prevLayer!)
        DispatchQueue.global().async {
            self.session?.startRunning()
        }
    }

}
