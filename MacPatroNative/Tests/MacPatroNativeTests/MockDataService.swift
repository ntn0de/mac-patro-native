
import Foundation
import Combine
@testable import MacPatroKit

class MockDataService: DataServiceProtocol {
    var dataDidUpdate: AnyPublisher<Void, Never> {
        return PassthroughSubject<Void, Never>().eraseToAnyPublisher()
    }
    
    var yearData: YearData?
    var error: Error?
    var lastIgnoringCache: Bool?

    func loadData(forYear year: Int, bundle: Bundle, ignoringCache: Bool, completion: @escaping (Result<YearData, Error>) -> Void) {
        lastIgnoringCache = ignoringCache
        if let error = error {
            completion(.failure(error))
        } else if let yearData = yearData {
            completion(.success(yearData))
        }
    }
}
