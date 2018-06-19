//
//  AVChoiceVC.swift
//  ios12 Sampler
//
//  Created by Testing on 13/06/18.
//  Copyright © 2018 Testing. All rights reserved.
//

import UIKit
import AVFoundation

class AVChoiceVC: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate,UIPopoverPresentationControllerDelegate {

    var imagePicker: UIImagePickerController!
    @IBOutlet weak var CameraView: UIView!
    var session: AVCaptureSession?
    var device: AVCaptureDevice?
    var input: AVCaptureDeviceInput?
    var output: AVCaptureMetadataOutput?
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

    @IBAction func btnActionFind(_ sender: UIButton) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "AVScannedObjectListVC")  as! AVScannedObjectListVC
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func btnActionBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func btnActionScan(_ sender: UIButton) {
        showActionSheetForScanObjectAndImage()
    }
    func showActionSheetForScanObjectAndImage() {
        let actionSheetController = UIAlertController(title: "Please select option ", message: "", preferredStyle: .alert)
        
        let cancelActionButton = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)
        
        let saveActionButton = UIAlertAction(title: "Scan Photos", style: .default) { _ in
            print("Scan Photos")
            self.openCamera()
        }
        actionSheetController.addAction(saveActionButton)
        
        let deleteActionButton = UIAlertAction(title: "Scan Objects", style: .default) { _ in
            print("Scan Objects")
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "ScanObjectsVC") as! ScanObjectsVC
            self.navigationController?.pushViewController(vc, animated: true)
        }
        actionSheetController.addAction(deleteActionButton)

        self.present(actionSheetController, animated: true, completion: nil)
    }
    func openCamera()  {
        imagePicker =  UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
    }
    //MARK: - Add image to Library
    func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imagePicker.dismiss(animated: true, completion: nil)
        let alert = UIAlertController(title: "Do you want to save image", message: "", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
            let img = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
            self.SaveImageToLocal(image:img)
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { action in
    
        }))
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = self.view.bounds
        }
        self.present(alert, animated: true, completion: nil)
    }
    func SaveImageToLocal(image:UIImage){
        do {
            let documentDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
            
            let alert = UIAlertController(title: "Enter Photo Name", message: "", preferredStyle: .alert)
            alert.addTextField { (textField) in
                textField.placeholder = "Please Enter Photo Name"
            }
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
                let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
                print("Text field: \((textField?.text)!)")
                let documentURL = documentDirectory.appendingPathComponent((textField?.text)! + ".\(AVScannedObjectListVC.kPng)")
                DispatchQueue.global().async {
                    if !FileManager.default.fileExists(atPath: documentURL.path) {
                        do {
                            try image.pngData()!.write(to: documentURL)
                            self.OkAlertwithMessage(message: "Image Added Successfully")
                        } catch {
                            print(error)
                        }
                    } else {
                        print("Image Not Added")
                    }

                }
            }))
            self.present(alert, animated: true, completion: nil)
        } catch {
            print(error)
        }
    }
    func OkAlertwithMessage(message:String) {
        let alertView = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: { (alert) in
            
        })
        alertView.addAction(action)
        self.present(alertView, animated: true, completion: nil)
    }
    func createSession() {
        session = AVCaptureSession()
        device = AVCaptureDevice.default(for: .video)
        
        var error: NSError? = nil
        do {
            input = try AVCaptureDeviceInput(device: device!)
        } catch  {
            print(error)
        }
        
        if error == nil {
            session?.addInput(input!)
        } else {
            print("camera input error: \(String(describing: error))")
        }
        
        prevLayer = AVCaptureVideoPreviewLayer(session: session!)
        let del = UIApplication.shared.delegate as? AppDelegate
        prevLayer?.frame = (del?.window?.frame)!
        prevLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        CameraView.layer.addSublayer(prevLayer!)
        session?.startRunning()
    }
}
