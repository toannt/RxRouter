import Foundation
import UIKit

public protocol ViewControllerConvertible {
    func asViewController() throws -> UIViewController
}

extension UIViewController: ViewControllerConvertible {
    public func asViewController() throws -> UIViewController {
        return self
    }
}
