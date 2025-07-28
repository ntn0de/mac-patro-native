
import Foundation
@testable import MacPatroKit

class MockDataService: DataServiceProtocol {
    var yearData: YearData?
    var error: Error?

    func loadData(forYear year: Int, bundle: Bundle, completion: @escaping (Result<YearData, Error>) -> Void) {
        if let error = error {
            completion(.failure(error))
        } else if let yearData = yearData {
            completion(.success(yearData))
        }
    }
}
