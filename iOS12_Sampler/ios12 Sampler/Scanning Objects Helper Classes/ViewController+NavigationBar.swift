/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Navigation bar management for the main view controller.
*/

import Foundation
import UIKit

extension ScanObjectsVC {
    
    func setupNavigationBar() {
        backButton = UIBarButtonItem(title: "Back", style: .plain, target: self,
                                     action: #selector(previousButtonTapped(_:)))
        let startOverButton = UIBarButtonItem(title: "Restart", style: .plain, target: self,
                                              action: #selector(restartButtonTapped(_:)))
        let navigationItem = UINavigationItem(title: "Start")
        navigationItem.leftBarButtonItem = backButton
        navigationItem.rightBarButtonItem = startOverButton
        navigationBar!.items = [navigationItem]
        
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        navigationBar.isTranslucent = true
    }
    
    func showBackButton(_ show: Bool) {
        guard let navBar = navigationBar, let navItem = navBar.items?.first else { return }
        if show {
            navItem.leftBarButtonItem = backButton
        } else {
            navItem.leftBarButtonItem = nil
        }
    }
    
    func setNavigationBarTitle(_ title: String) {
        guard let navBar = navigationBar, let navItem = navBar.items?.first else { return }
        navItem.title = title
    }
}
