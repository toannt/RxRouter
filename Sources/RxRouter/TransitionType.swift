import Foundation
import RxSwift
import UIKit

public protocol TransitionType {
    func asCompletable() -> Completable
}

public extension TransitionType {
    func then(_ second: TransitionType) -> TransitionType {
        return SerialTransition(first: self, second: second)
    }
    
    func and(_ second: TransitionType) -> TransitionType {
        return ParallelTransition(first: self, second: second)
    }
    
    func delay(_ interval: DispatchTimeInterval) -> TransitionType {
        return DelayTransition(delay: interval, source: self)
    }
}

public struct Transition: TransitionType {
    public typealias TransitionClosure = (@escaping ()->Void ) throws -> Void
    private let closure: TransitionClosure
    
    public init(closure: @escaping TransitionClosure) {
        self.closure = closure
    }
    
    public func asCompletable() -> Completable {
        return Completable.create { [closure] callback -> Disposable in
            do {
                try closure {
                    callback(.completed)
                }
            } catch {
                callback(.error(error))
            }
            return Disposables.create()
        }
    }
}

public enum TransitionError: Error {
    case missing(description: String?)
}


public extension Transition {
    static func push(_ controller: ViewControllerConvertible, into nav: UINavigationController?, animated: Bool = true) -> Self {
        Transition { [weak nav] completion in
            guard let nav = nav else {
                throw TransitionError.missing(description: "PUSH failed: Missing navigation controller")
            }
            nav.pushViewController(try controller.asViewController(), animated: animated)
            completion()
        }
    }
    
    static func present(_ controller: ViewControllerConvertible, from presentingVc: UIViewController?, animated: Bool = true) -> Self {
        Transition { [weak presentingVc] completion in
            guard let presentingVc = presentingVc else {
                throw TransitionError.missing(description: "PRESENT failed: Missing presenting view controller")
            }
            
            presentingVc.present(try controller.asViewController(), animated: animated, completion: completion)
        }
    }
    
    static func dismiss(_ controller: UIViewController?, animated: Bool = true) -> Self {
        Transition { [weak controller] completion in
            guard let controller = controller else {
                throw TransitionError.missing(description: "DIMISS failed: Missing view controller")
            }
            
            controller.dismiss(animated: animated, completion: completion)
        }
    }
    
    static func back(from navController: UINavigationController?, animated: Bool = true) -> Self {
        Transition { [weak navController] completion in
            guard let navController = navController else {
                throw TransitionError.missing(description: "BACK failed: Missing navigation controller")
            }
            
            navController.popViewController(animated: animated)
            completion()
        }
    }
    
    static func popToRoot(from navController: UINavigationController?, animated: Bool = true) -> Self {
        Transition { [weak navController] completion in
            guard let navController = navController else {
                throw TransitionError.missing(description: "POP-TO-ROOT failed: Missing navigation controller")
            }
            
            navController.popToRootViewController(animated: animated)
            completion()
        }
    }
}


struct SerialTransition: TransitionType {
    let first: TransitionType
    let second: TransitionType
    
    func asCompletable() -> Completable {
        first.asCompletable().concat(second.asCompletable())
    }
}

struct ParallelTransition: TransitionType {
    let first: TransitionType
    let second: TransitionType
    
    func asCompletable() -> Completable {
        return Completable.zip(first.asCompletable(), second.asCompletable())
    }
}

struct DelayTransition: TransitionType {
    let delay: DispatchTimeInterval
    let source: TransitionType
    
    func asCompletable() -> Completable {
        Completable.empty().delay(delay, scheduler: MainScheduler.instance).concat(source.asCompletable())
    }
}
