/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main view controller for the object scanning UI.
*/

import UIKit
import SceneKit
import ARKit

class ScanObjectsVC: UIViewController, ARSCNViewDelegate, ARSessionDelegate, UIDocumentPickerDelegate {
    
    static let serialQueue = DispatchQueue(label: Bundle.main.bundleIdentifier! + ".serialSceneKitQueue")
    
    static let appStateChangedNotification = Notification.Name("ApplicationStateChanged")
    static let appStateUserInfoKey = "AppState"
    
    static var instance: ScanObjectsVC?
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var nextButton: RoundedButton!
    var backButton: UIBarButtonItem!
    @IBOutlet weak var instructionView: UIVisualEffectView!
    @IBOutlet weak var instructionLabel: MessageLabel!
    @IBOutlet weak var loadModelButton: RoundedButton!
    @IBOutlet weak var flashlightButton: FlashlightButton!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var sessionInfoView: UIVisualEffectView!
    @IBOutlet weak var sessionInfoLabel: UILabel!
    @IBOutlet weak var toggleInstructionsButton: RoundedButton!
    
    internal var internalState: State = .startARSession
    
    internal var scan: Scan?
    
    private var initialARReferenceObject: ARReferenceObject?
    
    internal var testRun: TestRun?
    
    internal var messageExpirationTimer: Timer?
    internal var timeOfLastSessionStatusChange: TimeInterval?
    
    var modelURL: URL? {
        didSet {
            if let url = modelURL {
                displayMessage("3D model \"\(url.lastPathComponent)\" received.", expirationTime: 3.0)
            }
            if let scannedObject = self.scan?.scannedObject {
                scannedObject.set3DModel(modelURL)
            }
            if let dectectedObject = self.testRun?.detectedObject {
                dectectedObject.set3DModel(modelURL)
            }
        }
    }
    
    // MARK: - Application Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ScanObjectsVC.instance = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        // Prevent the screen from being dimmed after a while.
        UIApplication.shared.isIdleTimerDisabled = true
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(scanningStateChanged), name: Scan.stateChangedNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(ghostBoundingBoxWasCreated),
                                       name: ScannedObject.ghostBoundingBoxCreatedNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(ghostBoundingBoxWasRemoved),
                                       name: ScannedObject.ghostBoundingBoxRemovedNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(boundingBoxWasCreated),
                                       name: ScannedObject.boundingBoxCreatedNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(scanPercentageChanged),
                                       name: BoundingBox.scanPercentageChangedNotification, object: nil)
        
        setupNavigationBar()
        
        // Make sure the application launches in .startARSession state.
        // Entering this state will run() the ARSession.
        state = .startARSession
    }
    
    // MARK: - UI Event Handling
    
    @IBAction func restartButtonTapped(_ sender: Any) {
        if let scan = scan, scan.boundingBoxExists {
            let title = "Start over?"
            let message = "Discard the current scan and start over?"
            self.showAlert(title: title, message: message, buttonTitle: "Yes", showCancel: true) { _ in
                self.state = .startARSession
            }
        } else if testRun != nil {
            let title = "Start over?"
            let message = "Discard this scan and start over?"
            self.showAlert(title: title, message: message, buttonTitle: "Yes", showCancel: true) { _ in
                self.state = .startARSession
            }
        } else {
            self.state = .startARSession
        }
    }
    
    func backFromBackground() {
        if state == .scanning {
            let title = "Warning: Scan may be broken"
            let message = "The scan was interrupted. It is recommended to restart the scan."
            let buttonTitle = "Restart Scan"
            self.showAlert(title: title, message: message, buttonTitle: buttonTitle, showCancel: true) { _ in
                self.state = .notReady
            }
        }
    }
    
    @IBAction func previousButtonTapped(_ sender: Any) {
        switchToPreviousState()
    }
    
    @IBAction func nextButtonTapped(_ sender: Any) {
        switchToNextState()
    }
    
    @IBAction func loadModelButtonTapped(_ sender: Any) {
        let documentPicker = UIDocumentPickerViewController(documentTypes: ["com.pixar.universal-scene-description-mobile"], in: .import)
        documentPicker.delegate = self
        
        documentPicker.modalPresentationStyle = .overCurrentContext
        documentPicker.popoverPresentationController?.sourceView = self.loadModelButton
        documentPicker.popoverPresentationController?.sourceRect = self.loadModelButton.bounds
        
        DispatchQueue.main.async {
            self.present(documentPicker, animated: true, completion: nil)
        }
    }
    
    @IBAction func toggleFlashlightButtonTapped(_ sender: Any) {
        flashlightButton.toggledOn = !flashlightButton.toggledOn
    }
    
    @IBAction func toggleInstructionsButtonTapped(_ sender: Any) {
        if toggleInstructionsButton.toggledOn {
            instructionView.isHidden = true
            toggleInstructionsButton.toggledOn = false
        } else {
            instructionView.isHidden = false
            toggleInstructionsButton.toggledOn = true
        }
    }
    
    func displayInstruction(_ message: Message) {
        instructionView.isHidden = false
        instructionLabel.display(message)
        toggleInstructionsButton.toggledOn = true
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard !urls.isEmpty else { return }
        modelURL = urls[0]
    }
    
    func showAlert(title: String, message: String, buttonTitle: String = "OK", showCancel: Bool = false, buttonHandler: ((UIAlertAction) -> Void)? = nil) {
        print(title + "\n" + message)
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: buttonTitle, style: .default, handler: buttonHandler))
        if showCancel {
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        }
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func testObjectDetection() {
        guard let scan = scan, scan.boundingBoxExists else {
            print("Error: Bounding box not yet created.")
            return
        }
        
        scan.createReferenceObject { scannedObject in
            if let object = scannedObject {
                self.testRun?.setReferenceObject(object, screenshot: scan.screenshot)

                // Delete the scan to make sure that users cannot go back from
                // testing to scanning, because:
                // 1. Testing and scanning require running the ARSession with different configurations,
                //    thus the scanned environment is lost when starting a test.
                // 2. We encourage users to move the scanned object during testing, which invalidates
                //    the feature point cloud which was captured during scanning.
                self.scan = nil
                self.displayInstruction(Message("""
                    Test detection of the object from different angles. Consider moving the object to different environments and test there.
                    """))
            } else {
                let title = "Scan failed"
                let message = "Saving the scan failed."
                let buttonTitle = "Restart Scan"
                self.showAlert(title: title, message: message, buttonTitle: buttonTitle, showCancel: false) { _ in
                    self.state = .startARSession
                }
            }
        }
    }
    
    func createAndShareReferenceObject() {
        
        guard let testRun = self.testRun, let object = testRun.referenceObject, let name = object.name else {
            print("Error: Missing scanned object.")
            return
        }
        DispatchQueue.global().async {
            do {
                let documentDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
                
                let alert = UIAlertController(title: "Enter object Name", message: "", preferredStyle: .alert)
                alert.addTextField { (textField) in
                    textField.placeholder = "Please Enter object Name"
                }
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
                    let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
                    print("Text field: \((textField?.text)!)")
                    let documentURL = documentDirectory.appendingPathComponent((textField?.text)! + ".arobject")
                    DispatchQueue.global().async {
                        do {
                            try object.export(to: documentURL, previewImage: testRun.previewImage)
                        } catch {
                            fatalError("Failed to save the file to \(documentURL)")
                        }
                        DispatchQueue.main.async {
                            self.navigationController?.popViewController(animated: true)
                        }
                        
                        //                    // Initiate a share sheet for the scanned object
                        //                    let airdropShareSheet = ShareScanViewController(sourceView: self.nextButton, sharedObject: documentURL)
                        //                    DispatchQueue.main.async {
                        //                        self.present(airdropShareSheet, animated: true, completion: nil)
                        //                    }
                    }
                }))
                self.present(alert, animated: true, completion: nil)
            } catch {
                print(error)
            }
        }
        
//        let documentURL = FileManager.default.temporaryDirectory.appendingPathComponent(name + ".arobject")
//        
//        DispatchQueue.global().async {
//            do {
//                try object.export(to: documentURL, previewImage: testRun.previewImage)
//            } catch {
//                fatalError("Failed to save the file to \(documentURL)")
//            }
//            // Initiate a share sheet for the scanned object
//            let airdropShareSheet = ShareScanViewController(sourceView: self.nextButton, sharedObject: documentURL)
//            DispatchQueue.main.async {
//                self.present(airdropShareSheet, animated: true, completion: nil)
//            }
//        }
    }
    
    var limitedTrackingTimer: Timer?
    
    func startLimitedTrackingTimer() {
        guard limitedTrackingTimer == nil else { return }
        
        limitedTrackingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            self.cancelLimitedTrackingTimer()
            guard let scan = self.scan else { return }
            if scan.state == .defineBoundingBox || scan.state == .scanning || scan.state == .adjustingOrigin {
                let title = "Limited Tracking"
                let message = "Low tracking quality - it is unlikely that a good reference object can be generated from this scan."
                let buttonTitle = "Restart Scan"
                
                self.showAlert(title: title, message: message, buttonTitle: buttonTitle, showCancel: true) { _ in
                    self.state = .startARSession
                }
            }
        }
    }
    
    func cancelLimitedTrackingTimer() {
        limitedTrackingTimer?.invalidate()
        limitedTrackingTimer = nil
    }
    
    var maxScanTimeTimer: Timer?
    
    func startMaxScanTimeTimer() {
        guard maxScanTimeTimer == nil else { return }
        
        let timeout: TimeInterval = 60.0 * 5
        
        maxScanTimeTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { _ in
            self.cancelMaxScanTimeTimer()
            guard self.state == .scanning else { return }
            let title = "Scan is taking too long"
            let message = "Scanning consumes a lot of resources. This scan has been running for \(Int(timeout)) s. Consider closing the app and letting the device rest for a few minutes."
            let buttonTitle = "OK"
            self.showAlert(title: title, message: message, buttonTitle: buttonTitle, showCancel: true)
        }
    }
    
    func cancelMaxScanTimeTimer() {
        maxScanTimeTimer?.invalidate()
        maxScanTimeTimer = nil
    }
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        
        updateSessionInfoLabel(for: camera.trackingState)
        
        switch camera.trackingState {
        case .notAvailable:
            state = .notReady
        case .limited(let reason):
            switch state {
            case .startARSession:
                state = .notReady
            case .notReady, .testing:
                break
            case .scanning:
                if let scan = scan {
                    switch scan.state {
                    case .ready:
                        state = .notReady
                    case .defineBoundingBox, .scanning, .adjustingOrigin:
                        if reason == .relocalizing {
                            // If ARKit is relocalizing we should abort the current scan
                            // as this can cause unpredictable distortions of the map.
                            print("Warning: ARKit is relocalizing")
                            
                            let title = "Warning: Scan may be broken"
                            let message = "A gap in tracking has occurred. It is recommended to restart the scan."
                            let buttonTitle = "Restart Scan"
                            self.showAlert(title: title, message: message, buttonTitle: buttonTitle, showCancel: true) { _ in
                                self.state = .notReady
                            }
                            
                        } else {
                            // Suggest the user to restart tracking after a while.
                            startLimitedTrackingTimer()
                        }
                    }
                }
            }
        case .normal:
            if limitedTrackingTimer != nil {
                cancelLimitedTrackingTimer()
            }
            
            switch state {
            case .startARSession, .notReady:
                state = .scanning
            case .scanning, .testing:
                break
            }
        }
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        scan?.updateOnEveryFrame(frame)
        testRun?.updateOnEveryFrame()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let objectAnchor = anchor as? ARObjectAnchor {
            if let testRun = self.testRun, objectAnchor.referenceObject == testRun.referenceObject {
                testRun.successfulDetection(objectAnchor)
                let messageText = """
                    Object successfully detected from this angle.

                    """ + testRun.statistics
                displayMessage(messageText, expirationTime: testRun.resultDisplayDuration)
            }
        } else if state == .scanning, let planeAnchor = anchor as? ARPlaneAnchor {
            scan?.scannedObject.tryToAlignWithPlanes([planeAnchor])
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if state == .scanning, let planeAnchor = anchor as? ARPlaneAnchor {
            scan?.scannedObject.tryToAlignWithPlanes([planeAnchor])
        }
    }
    
    @objc
    func scanPercentageChanged(_ notification: Notification) {
        guard let percentage = notification.userInfo?[BoundingBox.scanPercentageUserInfoKey] as? Int else { return }
        
        // Switch to the next state if the scan is complete.
        if percentage >= 100 {
            switchToNextState()
            return
        }
        DispatchQueue.main.async {
            self.setNavigationBarTitle("Scan (\(percentage)%)")
        }
    }
}
