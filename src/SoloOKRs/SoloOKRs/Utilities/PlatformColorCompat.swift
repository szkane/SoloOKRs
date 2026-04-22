import SwiftUI

#if canImport(UIKit)
import UIKit

typealias NSColor = UIColor

extension UIColor {
    static var windowBackgroundColor: UIColor { .systemBackground }
    static var controlBackgroundColor: UIColor { .secondarySystemBackground }
    static var textBackgroundColor: UIColor { .secondarySystemBackground }
    static var separatorColor: UIColor { .separator }
}

extension Color {
    init(nsColor color: UIColor) {
        self.init(uiColor: color)
    }
}
#endif
