/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A custom label that displays instructions for the scanning procedure's current step.
*/

import UIKit

class Message {
    // The title and body of this message
    private(set) var text: NSMutableAttributedString
    
    init(_ body: String, title: String? = nil) {
        if let title = title {
            // Make the title bold
            text = NSMutableAttributedString(string: "\(title)\n\(body)")
            let titleRange = NSRange(location: 0, length: title.count)
            text.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 17), range: titleRange)
        } else {
            text = NSMutableAttributedString(string: body)
        }
    }
    
    func printToConsole() {
        print(text.string)
    }
}

class MessageLabel: UILabel {
        
    override var intrinsicContentSize: CGSize {
        var contentSize = super.intrinsicContentSize
        contentSize.width += 20
        contentSize.height += 20
        return contentSize
    }
    
    func display(_ message: Message) {
        DispatchQueue.main.async {
            self.attributedText = message.text
            self.isHidden = false
        }
    }
    
    func clear() {
        DispatchQueue.main.async {
            self.text = ""
            self.isHidden = true
        }
    }
}
