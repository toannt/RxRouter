import Foundation
import RxSwift
import UIKit

public class Router<Route> {
    private let routing: (Route) -> TransitionType
    
    public init(routing: @escaping (Route) -> TransitionType) {
        self.routing = routing
    }
    
    public convenience init<Handler>(handler: Handler) where Handler: RoutingType, Handler.Route == Route {
        self.init(routing: handler.transition(for:))
    }
    
    public func navigate(to route: Route) -> Completable {
        return routing(route).asCompletable()
    }
}
