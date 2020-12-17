import Foundation
import UIKit

public extension UIViewController {
    var topController: UIViewController {
        if let presentedVc = self.presentedViewController {
            return presentedVc.topController
        }
        
        if let navigationVc = self as? UINavigationController {
            return navigationVc.visibleViewController?.topController ?? self
        }
        
        if let tabarVc = self as? UITabBarController {
            return tabarVc.selectedViewController?.topController ?? self
        }
        
        return self
    }
}
