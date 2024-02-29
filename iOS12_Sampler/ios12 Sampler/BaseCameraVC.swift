//
//  BaseCameraVC.swift
//  ios12 Sampler
//
//  Created by Dhruvil Vora on 29/02/24.
//  Copyright © 2024 Testing. All rights reserved.
//

import UIKit
import AVFoundation

class BaseCameraVC: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    // AVCapture variables
    private var session: AVCaptureSession?
    private var device: AVCaptureDevice?
    private var input: AVCaptureDeviceInput?
    private var output: AVCaptureMetadataOutput?
    var prevLayer: AVCaptureVideoPreviewLayer?

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
        DispatchQueue.global().async {
            self.session?.startRunning()
        }
    }
}
