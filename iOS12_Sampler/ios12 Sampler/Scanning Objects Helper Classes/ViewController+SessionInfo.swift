/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Managemenent of session information communication to the user.
*/

import UIKit
import ARKit

extension ScanObjectsVC {
    
    func updateSessionInfoLabel(for trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        var message: String = ""
        let stateString = state == .testing ? "Detecting" : "Scanning"
        
        switch trackingState {
            
        case .notAvailable:
            message = "\(stateString) not possible: \(trackingState.presentationString)"
            timeOfLastSessionStatusChange = Date().timeIntervalSince1970
            
        case .limited:
            message = "\(stateString) might not work: \(trackingState.presentationString)"
            timeOfLastSessionStatusChange = Date().timeIntervalSince1970
            
        default:
            // Defer clearing the info label if the last message was less than 3 seconds ago.
            let now = Date().timeIntervalSince1970
            if let timeOfLastStatusChange = timeOfLastSessionStatusChange, now - timeOfLastStatusChange < 3.0 {
                let timeToKeepLastMessageOnScreen = 3.0 - (now - timeOfLastStatusChange)
                startMessageExpirationTimer(duration: timeToKeepLastMessageOnScreen)
                
                return
            }
            
            // No feedback needed when tracking is normal.
            message = ""
        }
        
        sessionInfoLabel.text = message
        sessionInfoView.isHidden = false
    }
    
    func displayMessage(_ message: String, expirationTime: TimeInterval) {
        DispatchQueue.main.async {
            self.sessionInfoLabel.text = message
            self.sessionInfoView.isHidden = false
            self.startMessageExpirationTimer(duration: expirationTime)
        }
    }
    
    func startMessageExpirationTimer(duration: TimeInterval) {
        cancelMessageExpirationTimer()
        
        messageExpirationTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { (timer) in
            self.cancelMessageExpirationTimer()
            self.sessionInfoLabel.text = ""
            self.sessionInfoView.isHidden = true
        }
    }
    
    func cancelMessageExpirationTimer() {
        messageExpirationTimer?.invalidate()
        messageExpirationTimer = nil
    }
}
