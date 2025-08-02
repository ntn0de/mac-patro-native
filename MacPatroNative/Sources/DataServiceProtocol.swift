
import Foundation
import Combine

public protocol DataServiceProtocol {
    var dataDidUpdate: AnyPublisher<Void, Never> { get }
    func loadData(forYear year: Int, bundle: Bundle, completion: @escaping (Result<YearData, Error>) -> Void)
}
