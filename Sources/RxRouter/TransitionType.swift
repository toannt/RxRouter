import Foundation
import RxSwift
import UIKit

public protocol TransitionType {
    func asCompletable() -> Completable
}

public struct Transition: TransitionType {
    public typealias TransitionExecution = (@escaping (Error?)->Void ) -> Void
    private let execution: TransitionExecution
    
    public init(execution: @escaping TransitionExecution) {
        self.execution = execution
    }
    
    public func asCompletable() -> Completable {
        return Completable.create { [execution] callback -> Disposable in
            execution { error in
                if let error = error {
                    callback(.error(error))
                } else {
                    callback(.completed)
                }
            }
            return Disposables.create()
        }.subscribe(on: MainScheduler.instance)
    }
}

public enum TransitionError: Error {
    case missing(description: String?)
}

public extension Transition {
    func then(_ second: Self) -> Self {
        return Transition { completion in
            self.execution { firstError in
                if let error = firstError {
                    return completion(error)
                }
                
                self.execution { secondError in
                    completion(secondError)
                }
            }
        }
    }
    
    func and(_ second: Self) -> Self {
        return Transition { completion in
            let dispatchGroup = DispatchGroup()
            var transitionError: Error?
            
            dispatchGroup.enter()
            self.execution { error in
                transitionError = error
                dispatchGroup.leave()
            }
            
            dispatchGroup.enter()
            second.execution { error in
                transitionError = error
                dispatchGroup.leave()
            }
            
            dispatchGroup.notify(queue: DispatchQueue.main) {
                completion(transitionError)
            }
        }
    }
    
    func delayStart(_ interval: DispatchTimeInterval) -> Self {
        return Transition { completion in
            DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
                self.execution { error in
                    completion(error)
                }
            }
        }
    }
    
    func delayEnd(_ interval: DispatchTimeInterval) -> Self {
        return Transition { completion in
            self.execution { error in
                DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
                    completion(error)
                }
            }
        }
    }
}

public extension Transition {
    static func push(_ controller: ViewControllerConvertible, into nav: UINavigationController?, animated: Bool = true) -> Self {
        Transition { [weak nav] completion in
            do {
                guard let nav = nav else {
                    throw TransitionError.missing(description: "PUSH failed: Missing navigation controller")
                }
                nav.pushViewController(try controller.asViewController(), animated: animated)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    static func present(_ controller: ViewControllerConvertible, from presentingVc: UIViewController?, animated: Bool = true) -> Self {
        Transition { [weak presentingVc] completion in
            do {
                guard let presentingVc = presentingVc else {
                    throw TransitionError.missing(description: "PRESENT failed: Missing presenting view controller")
                }
                presentingVc.present(try controller.asViewController(), animated: animated) {
                    completion(nil)
                }
            } catch {
                completion(error)
            }
        }
    }
    
    static func dismiss(_ controller: UIViewController?, animated: Bool = true) -> Self {
        Transition { [weak controller] completion in
            do {
                guard let controller = controller else {
                    throw TransitionError.missing(description: "DIMISS failed: Missing view controller")
                }
                
                controller.dismiss(animated: animated) {
                    completion(nil)
                }
            } catch {
                completion(error)
            }
        }
    }
    
    static func back(from navController: UINavigationController?, animated: Bool = true) -> Self {
        Transition { [weak navController] completion in
            do {
                guard let navController = navController else {
                    throw TransitionError.missing(description: "BACK failed: Missing navigation controller")
                }
                
                navController.popViewController(animated: animated)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    static func popToRoot(from navController: UINavigationController?, animated: Bool = true) -> Self {
        Transition { [weak navController] completion in
            do {
                guard let navController = navController else {
                    throw TransitionError.missing(description: "POP-TO-ROOT failed: Missing navigation controller")
                }
                
                navController.popToRootViewController(animated: animated)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
}
