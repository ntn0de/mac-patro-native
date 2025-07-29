
import Foundation

public final class DataService: DataServiceProtocol {
    
    public init() {}
    
    public enum DataServiceError: Error, Equatable {
        case fileNotFound
        case decodingFailed
        case remoteError
        case invalidRemoteData
    }
    
    private let remoteURLString = RemoteURL.urlString
    
    private func cacheDirectory() -> URL? {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("MacPatroNative")
    }
    
    private func cacheFileURL(forYear year: Int) -> URL? {
        guard let cacheDirectory = cacheDirectory() else { return nil }
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
        return cacheDirectory.appendingPathComponent("\(year).json")
    }
    
    private func isValid(data: YearData) -> Bool {
        // Failsafe checks: last_updated_at must be present, and we must have exactly 12 months of data.
        guard data.lastUpdatedAt > 0, data.data.count == 12 else {
            log("Validation failed: Invalid remote data received.")
            return false
        }
        log("Validation successful: Remote data is valid.")
        return true
    }
    
    public func loadData(forYear year: Int, bundle: Bundle = .main, completion: @escaping (Result<YearData, Error>) -> Void) {
        log("Requesting data for year: \(year)")

        // 1. Check for cached data first
        if let cacheURL = cacheFileURL(forYear: year), let data = try? Data(contentsOf: cacheURL) {
            log("Cache hit for year \(year).")
            do {
                let calendarYear = try JSONDecoder().decode(YearData.self, from: data)
                completion(.success(calendarYear))
                // After returning cached data, check for updates in the background.
                checkForUpdates(forYear: year, cachedData: calendarYear)
                return
            } catch {
                log("Corrupted cache for year \(year). Deleting and fetching fresh.")
                try? FileManager.default.removeItem(at: cacheURL)
            }
        }

        // 2. If no cache, fetch from remote, with fallback to bundled
        log("Cache miss for year \(year). Fetching fresh data.")
        fetchRemoteData(forYear: year) { remoteResult in
            DispatchQueue.main.async {
                switch remoteResult {
                case .success(let remoteYearData):
                    if self.isValid(data: remoteYearData) {
                        log("Remote fetch successful for year \(year). Caching.")
                        if let cacheURL = self.cacheFileURL(forYear: year), let data = try? JSONEncoder().encode(remoteYearData) {
                            try? data.write(to: cacheURL)
                        }
                        completion(.success(remoteYearData))
                    } else {
                        // If validation fails, treat it like a remote error and use bundled data.
                        self.loadBundledData(forYear: year, bundle: bundle, completion: completion)
                    }
                case .failure:
                    log("Remote fetch failed for year \(year). Falling back to bundled data.")
                    self.loadBundledData(forYear: year, bundle: bundle, completion: completion)
                }
            }
        }
    }
    
    private func loadBundledData(forYear year: Int, bundle: Bundle, completion: @escaping (Result<YearData, Error>) -> Void) {
        let fileName = "\(year)"
        guard let fileURL = bundle.url(forResource: fileName, withExtension: "json") else {
            completion(.failure(DataServiceError.fileNotFound))
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let calendarYear = try JSONDecoder().decode(YearData.self, from: data)
            log("Successfully loaded bundled data for year \(year). Caching it.")
            if let cacheURL = self.cacheFileURL(forYear: year) {
                try? data.write(to: cacheURL)
            }
            completion(.success(calendarYear))
        } catch {
            completion(.failure(DataServiceError.decodingFailed))
        }
    }
    
    private func checkForUpdates(forYear year: Int, cachedData: YearData) {
        fetchRemoteData(forYear: year) { result in
            if case .success(let remoteData) = result,
               self.isValid(data: remoteData),
               remoteData.lastUpdatedAt > cachedData.lastUpdatedAt {
                log("Found newer data for year \(year). Updating cache in background.")
                if let cacheURL = self.cacheFileURL(forYear: year), let data = try? JSONEncoder().encode(remoteData) {
                    try? data.write(to: cacheURL)
                }
            } else {
                log("No new valid data found for year \(year).")
            }
        }
    }

    private func fetchRemoteData(forYear year: Int, completion: @escaping (Result<YearData, Error>) -> Void) {
        guard let url = URL(string: "\(remoteURLString)\(year).json") else {
            completion(.failure(DataServiceError.remoteError))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(DataServiceError.remoteError))
                return
            }
            do {
                let calendarYear = try JSONDecoder().decode(YearData.self, from: data)
                completion(.success(calendarYear))
            } catch {
                completion(.failure(DataServiceError.decodingFailed))
            }
        }.resume()
    }
}
