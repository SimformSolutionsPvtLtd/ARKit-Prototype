//
//  StatusViewController.swift
//  ios12 Sampler
//
//  Created by Dhruvil Vora on 11/01/24.
//  Copyright © 2024 Testing. All rights reserved.
//

import ARKit

class StatusViewController: UIViewController {

    enum MessageType: CaseIterable {
        case cameraQualityInfo
        case cameraQualityRecommendation
    }

    @IBOutlet weak var messageLabelView: UIVisualEffectView!

    @IBOutlet weak var resetButton: UIButton!

    @IBOutlet weak var messageLabel: UILabel!

    private var timers: [MessageType: Timer] = [:]

    private var autoHideDuration = 6

    var restartExperienceHandler: () -> Void = {}

    func showCameraQualityInfo(trackingState: ARCamera.TrackingState, autoHide: Bool) {
        cancelTimer(for: .cameraQualityInfo)
        showMessage(trackingState.presentationString, autoHide: autoHide)
    }

    func showRecommendationForCameraQuality(trackingState: ARCamera.TrackingState, duration: TimeInterval, autoHide: Bool) {
        cancelTimer(for: .cameraQualityRecommendation)
        showMessage(trackingState.recommendation ?? "", autoHide: autoHide)

        let timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.messageLabel.text = "\(trackingState.presentationString): \(trackingState.recommendation ?? "Not available")"
        }
        timers[.cameraQualityRecommendation] = timer
    }

    func showMessage(_ message: String, autoHide: Bool) {
        messageLabel.text = message
        if autoHide {
            let timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(autoHideDuration), repeats: false) { [weak self] _ in
                self?.messageLabel.text = message
            }
        }
    }

    func cancelTimer(for messageType: MessageType) {
        timers[messageType]?.invalidate()
        timers[messageType] = nil
    }

    func removeAllTimers() {
        for messageType in MessageType.allCases {
            cancelTimer(for: messageType)
        }
    }

    func showHideResetButton(isHidden: Bool) {
        resetButton.isHidden = isHidden
    }

    func scheduleGenericMessage(genericMsg: String, duration: TimeInterval, autoHide: Bool, messageType: MessageType) {
        showMessage(genericMsg, autoHide: autoHide)

        let timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.messageLabel.text = genericMsg
        }
        timers[messageType] = timer
    }
    @IBAction func onRestartButtonPressed(_ sender: UIButton) {
        restartExperienceHandler()
    }
}
