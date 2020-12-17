import Foundation

public protocol RoutingType {
    associatedtype Route
    func transition(for route: Route) -> TransitionType
}
