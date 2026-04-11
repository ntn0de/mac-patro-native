
import Foundation
import Combine

public protocol DataServiceProtocol {
    var dataDidUpdate: AnyPublisher<Void, Never> { get }
    func loadData(forYear year: Int, bundle: Bundle, ignoringCache: Bool, completion: @escaping (Result<YearData, Error>) -> Void)
}

public extension DataServiceProtocol {
    func loadData(forYear year: Int, bundle: Bundle, completion: @escaping (Result<YearData, Error>) -> Void) {
        loadData(forYear: year, bundle: bundle, ignoringCache: false, completion: completion)
    }
}
