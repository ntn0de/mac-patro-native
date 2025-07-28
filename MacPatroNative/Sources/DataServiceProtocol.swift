
import Foundation

public protocol DataServiceProtocol {
    func loadData(forYear year: Int, bundle: Bundle, completion: @escaping (Result<YearData, Error>) -> Void)
}
